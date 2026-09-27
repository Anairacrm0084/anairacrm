-- ANAIRA 068: atomic hotel inventory holds + transactional coupons + notification enqueue
create table if not exists public.anaira_inventory_holds (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_type_id uuid not null,
 check_in date not null,
 check_out date not null,
 rooms integer not null check (rooms > 0),
 status text not null default 'held' check (status in ('held','converted','released','expired')),
 expires_at timestamptz not null,
 booking_reservation_id uuid,
 idempotency_key text,
 created_at timestamptz not null default now(),
 released_at timestamptz,
 unique (restaurant_id,idempotency_key)
);
create index if not exists anaira_inventory_holds_lookup on public.anaira_inventory_holds(restaurant_id,room_type_id,check_in,check_out,status,expires_at);

alter table public.anaira_inventory_holds enable row level security;
drop policy if exists anaira_inventory_holds_tenant on public.anaira_inventory_holds;
create policy anaira_inventory_holds_tenant on public.anaira_inventory_holds for all to authenticated
using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

create or replace function public.anaira_create_inventory_hold(
 p_restaurant_id uuid,p_room_type_id uuid,p_check_in date,p_check_out date,p_rooms integer default 1,p_minutes integer default 10,p_idempotency_key text default null
) returns jsonb language plpgsql security invoker as $$
declare v booking_inventory%rowtype; d date; existing public.anaira_inventory_holds%rowtype; hold_id uuid;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 if p_rooms<=0 then raise exception 'Rooms must be positive'; end if;
 if p_minutes<1 or p_minutes>60 then raise exception 'Hold duration must be 1-60 minutes'; end if;
 if p_idempotency_key is not null then select * into existing from public.anaira_inventory_holds where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key; if found and existing.status='held' and existing.expires_at>now() then return to_jsonb(existing); end if; end if;
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
   select * into v from public.booking_inventory where restaurant_id=p_restaurant_id and room_type_id=p_room_type_id and stay_date=d for update;
   if not found then raise exception 'Inventory not configured for %',d; end if;
   if v.closed or (v.total_rooms-v.booked_rooms-v.held_rooms)<p_rooms then raise exception 'Insufficient availability for %',d; end if;
 end loop;
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
   update public.booking_inventory set held_rooms=held_rooms+p_rooms where restaurant_id=p_restaurant_id and room_type_id=p_room_type_id and stay_date=d;
 end loop;
 insert into public.anaira_inventory_holds(restaurant_id,room_type_id,check_in,check_out,rooms,expires_at,idempotency_key)
 values(p_restaurant_id,p_room_type_id,p_check_in,p_check_out,p_rooms,now()+make_interval(mins=>p_minutes),p_idempotency_key) returning id into hold_id;
 return jsonb_build_object('hold_id',hold_id,'status','held','expires_at',now()+make_interval(mins=>p_minutes));
end $$;

create or replace function public.anaira_release_inventory_hold(p_hold_id uuid,p_status text default 'released') returns jsonb language plpgsql security invoker as $$
declare h public.anaira_inventory_holds; d date; new_status text;
begin
 select * into h from public.anaira_inventory_holds where id=p_hold_id for update;
 if not found then raise exception 'Inventory hold not found'; end if;
 if h.status<>'held' then return jsonb_build_object('hold_id',h.id,'status',h.status); end if;
 new_status=case when p_status in ('released','expired','converted') then p_status else 'released' end;
 if new_status<>'converted' then
   for d in select generate_series(h.check_in,h.check_out-1,interval '1 day')::date loop
     update public.booking_inventory set held_rooms=greatest(held_rooms-h.rooms,0) where restaurant_id=h.restaurant_id and room_type_id=h.room_type_id and stay_date=d;
   end loop;
 end if;
 update public.anaira_inventory_holds set status=new_status,released_at=case when new_status<>'converted' then now() else released_at end where id=h.id;
 return jsonb_build_object('hold_id',h.id,'status',new_status);
end $$;

create or replace function public.anaira_expire_inventory_holds() returns integer language plpgsql security invoker as $$
declare h record; n integer:=0;
begin
 for h in select id from public.anaira_inventory_holds where status='held' and expires_at<=now() for update skip locked loop
   perform public.anaira_release_inventory_hold(h.id,'expired'); n:=n+1;
 end loop;
 return n;
end $$;

create or replace function public.anaira_validate_coupon(p_tenant_id uuid,p_code text,p_customer_id uuid default null,p_order_amount numeric default 0) returns jsonb language plpgsql security invoker as $$
declare c public.crm_coupon_definitions; used integer; customer_used integer; discount numeric;
begin
 select * into c from public.crm_coupon_definitions where tenant_id=p_tenant_id and upper(code)=upper(trim(p_code)) and active=true for update;
 if not found then return jsonb_build_object('valid',false,'reason','coupon_not_found'); end if;
 if c.starts_at is not null and now()<c.starts_at then return jsonb_build_object('valid',false,'reason','coupon_not_started'); end if;
 if c.ends_at is not null and now()>c.ends_at then return jsonb_build_object('valid',false,'reason','coupon_expired'); end if;
 select count(*) into used from public.crm_coupon_redemptions where coupon_id=c.id;
 if c.max_redemptions is not null and used>=c.max_redemptions then return jsonb_build_object('valid',false,'reason','coupon_limit_reached'); end if;
 if p_customer_id is not null then select count(*) into customer_used from public.crm_coupon_redemptions where coupon_id=c.id and customer_id=p_customer_id; if c.per_customer_limit is not null and customer_used>=c.per_customer_limit then return jsonb_build_object('valid',false,'reason','customer_limit_reached'); end if; end if;
 if c.discount_type='percent' then discount=round(greatest(p_order_amount,0)*c.discount_value/100,2); else discount=least(greatest(c.discount_value,0),greatest(p_order_amount,0)); end if;
 return jsonb_build_object('valid',true,'coupon_id',c.id,'code',c.code,'discount',discount,'discount_type',c.discount_type,'discount_value',c.discount_value);
end $$;

create or replace function public.anaira_redeem_coupon(p_tenant_id uuid,p_coupon_id uuid,p_customer_id uuid,p_reference_type text,p_reference_id text,p_discount numeric) returns jsonb language plpgsql security invoker as $$
declare c public.crm_coupon_definitions; used integer; customer_used integer; rid uuid;
begin
 select * into c from public.crm_coupon_definitions where id=p_coupon_id and tenant_id=p_tenant_id and active=true for update;
 if not found then raise exception 'Coupon not found'; end if;
 select count(*) into used from public.crm_coupon_redemptions where coupon_id=c.id;
 if c.max_redemptions is not null and used>=c.max_redemptions then raise exception 'Coupon redemption limit reached'; end if;
 select count(*) into customer_used from public.crm_coupon_redemptions where coupon_id=c.id and customer_id=p_customer_id;
 if c.per_customer_limit is not null and customer_used>=c.per_customer_limit then raise exception 'Customer coupon limit reached'; end if;
 insert into public.crm_coupon_redemptions(tenant_id,coupon_id,customer_id,reference_type,reference_id,discount_amount) values(p_tenant_id,c.id,p_customer_id,p_reference_type,p_reference_id,greatest(p_discount,0)) returning id into rid;
 return jsonb_build_object('redeemed',true,'redemption_id',rid,'discount',greatest(p_discount,0));
end $$;

create or replace function public.anaira_enqueue_notification(p_restaurant_id uuid,p_channel text,p_recipient text,p_template_key text,p_payload jsonb default '{}'::jsonb,p_provider text default null) returns uuid language plpgsql security invoker as $$
declare id uuid;
begin
 if p_channel not in ('email','sms','whatsapp','push') then raise exception 'Unsupported notification channel'; end if;
 insert into public.anaira_notification_queue(restaurant_id,channel,provider,recipient,template_key,body,payload) values(p_restaurant_id,p_channel,p_provider,p_recipient,p_template_key,coalesce(p_payload->>'body',p_template_key),coalesce(p_payload,'{}')) returning anaira_notification_queue.id into id;
 return id;
end $$;
