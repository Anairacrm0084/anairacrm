-- ANAIRA PHASE 13 — Production completion foundation
-- Apply after live 088_phase12_transactional_workflow_orchestration.
-- This migration is intentionally non-destructive. Provider credentials and physical-device E2E remain deployment checks.

create table if not exists public.anaira_hotel_inventory_holds (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_type_id uuid not null references public.hms_room_types(id) on delete cascade,
 reservation_id uuid references public.hms_reservations(id) on delete set null,
 check_in date not null,
 check_out date not null,
 rooms integer not null default 1 check (rooms > 0),
 status text not null default 'held' check(status in ('held','consumed','released','expired')),
 expires_at timestamptz,
 idempotency_key text not null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(restaurant_id,idempotency_key)
);
create index if not exists anaira_hotel_holds_lookup on public.anaira_hotel_inventory_holds(restaurant_id,room_type_id,check_in,check_out,status);
alter table public.anaira_hotel_inventory_holds enable row level security;
drop policy if exists anaira_hotel_holds_tenant on public.anaira_hotel_inventory_holds;
create policy anaira_hotel_holds_tenant on public.anaira_hotel_inventory_holds for all to authenticated
using(public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check(public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

create table if not exists public.anaira_phase13_release_checks (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid references public.restaurants(id) on delete cascade,
 check_key text not null, status text not null check(status in ('pass','fail','blocked')),
 evidence jsonb not null default '{}'::jsonb, checked_at timestamptz not null default now(),
 unique(restaurant_id,check_key)
);
alter table public.anaira_phase13_release_checks enable row level security;
drop policy if exists anaira_p13_release_checks on public.anaira_phase13_release_checks;
create policy anaira_p13_release_checks on public.anaira_phase13_release_checks for all to authenticated
using(public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check(public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

create or replace function public.anaira_phase13_hotel_inventory_hold(p_restaurant_id uuid,p_room_type_id uuid,p_check_in date,p_check_out date,p_rooms integer,p_idempotency_key text,p_reservation_id uuid default null,p_ttl_minutes integer default 15)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare h public.anaira_hotel_inventory_holds%rowtype; d date; available integer;
begin
 if p_check_out<=p_check_in or p_rooms<=0 then raise exception 'Invalid hotel hold request'; end if;
 select * into h from public.anaira_hotel_inventory_holds where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'hold_id',h.id,'status',h.status); end if;
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
  select greatest(0,coalesce(i.total_rooms,0)-coalesce(i.sold_rooms,0)-coalesce(i.blocked_rooms,0)-coalesce((select sum(x.rooms) from public.anaira_hotel_inventory_holds x where x.restaurant_id=p_restaurant_id and x.room_type_id=p_room_type_id and x.check_in<=d and x.check_out>d and x.status='held' and (x.expires_at is null or x.expires_at>now())),0)) into available
  from public.hms_inventory i where i.restaurant_id=p_restaurant_id and i.room_type_id=p_room_type_id and i.stay_date=d for update;
  if available is null or available<p_rooms then raise exception 'Hotel inventory unavailable for %',d; end if;
 end loop;
 insert into public.anaira_hotel_inventory_holds(restaurant_id,room_type_id,reservation_id,check_in,check_out,rooms,status,expires_at,idempotency_key)
 values(p_restaurant_id,p_room_type_id,p_reservation_id,p_check_in,p_check_out,p_rooms,'held',now()+make_interval(mins=>greatest(1,p_ttl_minutes)),p_idempotency_key) returning * into h;
 return jsonb_build_object('ok',true,'hold_id',h.id,'status',h.status,'expires_at',h.expires_at);
end $$;

create or replace function public.anaira_phase13_hotel_inventory_hold_release(p_restaurant_id uuid,p_hold_id uuid,p_action text default 'release')
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare h public.anaira_hotel_inventory_holds%rowtype; s text;
begin
 select * into h from public.anaira_hotel_inventory_holds where id=p_hold_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'Inventory hold not found'; end if;
 if p_action not in ('release','consume') then raise exception 'Invalid hold action'; end if;
 s:=case when p_action='consume' then 'consumed' else 'released' end;
 update public.anaira_hotel_inventory_holds set status=s,updated_at=now() where id=h.id;
 return jsonb_build_object('ok',true,'hold_id',h.id,'status',s);
end $$;

grant execute on function public.anaira_phase13_hotel_inventory_hold(uuid,uuid,date,date,integer,text,uuid,integer) to authenticated;
grant execute on function public.anaira_phase13_hotel_inventory_hold_release(uuid,uuid,text) to authenticated;

create or replace function public.anaira_phase13_pms_transition(p_restaurant_id uuid,p_reservation_id uuid,p_action text,p_room_id uuid default null,p_notes text default null)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.hms_reservations%rowtype; s public.hms_stays%rowtype; f public.hms_folios%rowtype;
begin
 select * into r from public.hms_reservations where id=p_reservation_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'HMS reservation not found'; end if;
 if p_action='confirm' then update public.hms_reservations set status='confirmed' where id=r.id;
 elsif p_action='no_show' then update public.hms_reservations set status='no_show' where id=r.id;
 elsif p_action='cancel' then update public.hms_reservations set status='cancelled' where id=r.id;
 elsif p_action='check_in' then
  if p_room_id is null then raise exception 'Room is required for check-in'; end if;
  insert into public.hms_stays(reservation_id,room_id,check_in_at,status,key_count,notes) values(r.id,p_room_id,now(),'in_house',1,p_notes) on conflict do nothing returning * into s;
  update public.hms_reservations set status='checked_in',room_id=p_room_id where id=r.id;
  update public.hms_rooms set status='occupied' where id=p_room_id and restaurant_id=p_restaurant_id;
  insert into public.hms_folios(reservation_id,guest_id,status,subtotal,tax,total,balance) select r.id,r.guest_id,'open',0,0,0,0 where not exists(select 1 from public.hms_folios x where x.reservation_id=r.id);
 elsif p_action='room_move' then
  if p_room_id is null then raise exception 'Target room is required'; end if;
  select * into s from public.hms_stays where reservation_id=r.id and status='in_house' order by check_in_at desc limit 1 for update;
  if s.id is null then raise exception 'No in-house stay found'; end if;
  update public.hms_rooms set status='available' where id=s.room_id and restaurant_id=p_restaurant_id;
  update public.hms_stays set room_id=p_room_id,notes=coalesce(p_notes,notes) where id=s.id;
  update public.hms_reservations set room_id=p_room_id where id=r.id;
  update public.hms_rooms set status='occupied' where id=p_room_id and restaurant_id=p_restaurant_id;
 elsif p_action='checkout' then
  select * into s from public.hms_stays where reservation_id=r.id and status='in_house' order by check_in_at desc limit 1 for update;
  if s.id is null then raise exception 'No in-house stay found'; end if;
  update public.hms_stays set status='checked_out',check_out_at=now(),notes=coalesce(p_notes,notes) where id=s.id;
  update public.hms_rooms set status='dirty',housekeeping_status='dirty' where id=s.room_id and restaurant_id=p_restaurant_id;
  update public.hms_reservations set status='checked_out' where id=r.id;
  select * into f from public.hms_folios where reservation_id=r.id order by created_at desc limit 1;
  if f.id is not null then update public.hms_folios set status='closed',balance=0 where id=f.id; end if;
  insert into public.hms_housekeeping_tasks(room_id,task_type,priority,status,due_at,notes) values(s.room_id,'checkout_cleaning','high','pending',now(),coalesce(p_notes,'Checkout cleaning'));
 else raise exception 'Unsupported PMS action: %',p_action; end if;
 return jsonb_build_object('ok',true,'reservation_id',r.id,'action',p_action);
end $$;
grant execute on function public.anaira_phase13_pms_transition(uuid,uuid,text,uuid,text) to authenticated;
