-- ANAIRA Inventory Smart Flow: physical-room booking blocks + real sell-rule enforcement.
alter table public.hms_rooms add column if not exists booking_enabled boolean not null default true;
alter table public.hms_rooms add column if not exists booking_block_reason text;
create table if not exists public.hms_room_inventory_blocks (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_id uuid not null references public.hms_rooms(id) on delete cascade, stay_date date not null, reason text,
 active boolean not null default true, created_by uuid, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(room_id,stay_date));
create index if not exists hms_room_inventory_blocks_lookup on public.hms_room_inventory_blocks(restaurant_id,room_id,stay_date,active);
alter table public.hms_room_inventory_blocks enable row level security;
drop policy if exists hms_room_inventory_blocks_tenant on public.hms_room_inventory_blocks;
create policy hms_room_inventory_blocks_tenant on public.hms_room_inventory_blocks for all to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create or replace function public.anaira_set_room_booking_block(p_restaurant_id uuid,p_room_id uuid,p_from date,p_to date,p_blocked boolean,p_reason text default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.hms_rooms%rowtype; d date; n integer:=0;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not(p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 if p_to<p_from then raise exception 'Invalid room block date range'; end if;
 select * into r from public.hms_rooms where id=p_room_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'Room not found'; end if;
 if p_blocked then
  if r.status in ('occupied','reserved') then raise exception 'Room % is currently % and cannot be blocked for sale',r.room_number,r.status; end if;
  for d in select generate_series(p_from,p_to,'1 day'::interval)::date loop
   insert into public.hms_room_inventory_blocks(restaurant_id,room_id,stay_date,reason,active,created_by,updated_at) values(p_restaurant_id,p_room_id,d,nullif(trim(p_reason),''),true,auth.uid(),now()) on conflict(room_id,stay_date) do update set active=true,reason=excluded.reason,updated_at=now(); n:=n+1;
  end loop;
 else update public.hms_room_inventory_blocks set active=false,updated_at=now() where restaurant_id=p_restaurant_id and room_id=p_room_id and stay_date between p_from and p_to; n:=1; end if;
 return jsonb_build_object('ok',true,'room_id',p_room_id,'blocked',p_blocked,'from',p_from,'to',p_to,'affected_days',n);
end $$;
revoke all on function public.anaira_set_room_booking_block(uuid,uuid,date,date,boolean,text) from public;
grant execute on function public.anaira_set_room_booking_block(uuid,uuid,date,date,boolean,text) to authenticated;
create or replace function public.anaira_room_sellable_count(p_restaurant_id uuid,p_room_type_id uuid,p_stay_date date) returns integer language sql stable security definer set search_path=public,pg_temp as $$
select greatest(0,count(*)::integer-count(*) filter(where lower(coalesce(rm.status,'')) in ('maintenance','out_of_order','blocked','inactive') or coalesce(rm.booking_enabled,true)=false or exists(select 1 from public.hms_room_inventory_blocks b where b.room_id=rm.id and b.stay_date=p_stay_date and b.active))::integer) from public.hms_rooms rm where rm.restaurant_id=p_restaurant_id and rm.room_type_id=p_room_type_id and coalesce(rm.active,true); $$;
revoke all on function public.anaira_room_sellable_count(uuid,uuid,date) from public;
grant execute on function public.anaira_room_sellable_count(uuid,uuid,date) to anon,authenticated;
-- Booking hold boundary enforces Stop Sell, COA/COD, cutoff, physical-room blocks and existing holds.
create or replace function public.anaira_phase13_hotel_inventory_hold(p_restaurant_id uuid,p_room_type_id uuid,p_check_in date,p_check_out date,p_rooms integer,p_idempotency_key text,p_reservation_id uuid default null,p_ttl_minutes integer default 15) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare h public.anaira_hotel_inventory_holds%rowtype; d date; available integer; i public.hms_inventory%rowtype; s public.hms_settings%rowtype;
begin
 if p_check_out<=p_check_in or p_rooms<=0 then raise exception 'Invalid hotel hold request'; end if;
 select * into h from public.anaira_hotel_inventory_holds where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'hold_id',h.id,'status',h.status); end if;
 select * into s from public.hms_settings where restaurant_id=p_restaurant_id limit 1;
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
  select * into i from public.hms_inventory where restaurant_id=p_restaurant_id and room_type_id=p_room_type_id and stay_date=d for update;
  if i.id is null then raise exception 'Hotel inventory unavailable for %',d; end if;
  if coalesce(i.stop_sell,false) then raise exception 'Booking is closed for %: Stop Sell is active',d; end if;
  if d=p_check_in and coalesce(i.close_on_arrival,false) then raise exception 'Arrival is closed for %',d; end if;
  if d=p_check_out and coalesce(i.close_on_departure,false) then raise exception 'Departure is closed for %',d; end if;
  available:=greatest(0,coalesce(i.total_rooms,0)-coalesce(i.sold_rooms,0)-coalesce(i.blocked_rooms,0)-coalesce((select count(*) from public.hms_room_inventory_blocks b join public.hms_rooms rm on rm.id=b.room_id where b.restaurant_id=p_restaurant_id and rm.room_type_id=p_room_type_id and b.stay_date=d and b.active),0)-coalesce((select sum(x.rooms) from public.anaira_hotel_inventory_holds x where x.restaurant_id=p_restaurant_id and x.room_type_id=p_room_type_id and x.check_in<=d and x.check_out>d and x.status='held' and (x.expires_at is null or x.expires_at>now())),0));
  if available<p_rooms then raise exception 'Hotel inventory unavailable for %',d; end if;
 end loop;
 insert into public.anaira_hotel_inventory_holds(restaurant_id,room_type_id,reservation_id,check_in,check_out,rooms,status,expires_at,idempotency_key) values(p_restaurant_id,p_room_type_id,p_reservation_id,p_check_in,p_check_out,p_rooms,'held',now()+make_interval(mins=>greatest(1,p_ttl_minutes)),p_idempotency_key) returning * into h;
 return jsonb_build_object('ok',true,'hold_id',h.id,'status',h.status,'expires_at',h.expires_at);
end $$;
revoke all on function public.anaira_phase13_hotel_inventory_hold(uuid,uuid,date,date,integer,text,uuid,integer) from public;
grant execute on function public.anaira_phase13_hotel_inventory_hold(uuid,uuid,date,date,integer,text,uuid,integer) to authenticated,anon;
