-- Anaira P2: Hotel/PMS/Booking market-parity runtime hardening.
-- Provider credentials are never fabricated. Provider-dependent work remains explicit/retryable.

create table if not exists public.anaira_booking_lifecycle_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.restaurants(id) on delete cascade,
  booking_id uuid not null references public.booking_reservations(id) on delete cascade,
  event_type text not null,
  idempotency_key text not null,
  actor_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(tenant_id,idempotency_key)
);
create index if not exists anaira_booking_lifecycle_events_booking_idx
  on public.anaira_booking_lifecycle_events(tenant_id,booking_id,created_at desc);
alter table public.anaira_booking_lifecycle_events enable row level security;
drop policy if exists anaira_booking_lifecycle_events_tenant on public.anaira_booking_lifecycle_events;
create policy anaira_booking_lifecycle_events_tenant on public.anaira_booking_lifecycle_events
for all to authenticated using (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id());

-- Transaction-safe cancellation. Inventory is released only inside the same transaction.
create or replace function public.anaira_cancel_hotel_booking(
  p_tenant_id uuid,
  p_booking_id uuid,
  p_reason text default null,
  p_idempotency_key text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; tx public.crm_booking_transactions%rowtype; hold_id uuid; evt public.anaira_booking_lifecycle_events%rowtype; fee numeric:=0; refundable numeric:=0;
begin
  if p_idempotency_key is not null then
    select * into evt from public.anaira_booking_lifecycle_events where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key;
    if found then return evt.payload || jsonb_build_object('idempotent',true); end if;
  end if;
  select * into b from public.booking_reservations where id=p_booking_id and restaurant_id=p_tenant_id for update;
  if not found then raise exception 'Booking not found'; end if;
  if b.status in ('cancelled','checked_out','no_show') then
    return jsonb_build_object('ok',true,'booking_id',b.id,'status',b.status,'idempotent',true);
  end if;
  select * into tx from public.crm_booking_transactions where booking_id=b.id order by created_at desc limit 1 for update;
  if tx.inventory_hold_id is not null then
    perform public.anaira_phase13_hotel_inventory_hold_release(p_tenant_id,tx.inventory_hold_id,'release');
  end if;
  -- Policy is evaluated from the stored reservation/property policy snapshot when available.
  fee:=coalesce((b.metadata->>'cancellation_fee')::numeric,0);
  refundable:=greatest(0,coalesce(b.total_amount,0)-fee);
  update public.booking_reservations set status='cancelled',payment_status=case when refundable>0 and payment_status='paid' then 'refund_pending' else payment_status end,
    cancellation_reason=coalesce(p_reason,cancellation_reason),cancelled_at=now(),updated_at=now() where id=b.id;
  if tx.id is not null then update public.crm_booking_transactions set state='cancelled',updated_at=now() where id=tx.id; end if;
  insert into public.anaira_booking_lifecycle_events(tenant_id,booking_id,event_type,idempotency_key,actor_id,payload)
  values(p_tenant_id,b.id,'booking.cancelled',coalesce(p_idempotency_key,'cancel:'||b.id||':'||extract(epoch from now())::bigint),auth.uid(),jsonb_build_object('ok',true,'booking_id',b.id,'status','cancelled','cancellation_fee',fee,'refundable_amount',refundable,'reason',p_reason))
  returning * into evt;
  return evt.payload;
end $$;
revoke execute on function public.anaira_cancel_hotel_booking(uuid,uuid,text,text) from anon;
grant execute on function public.anaira_cancel_hotel_booking(uuid,uuid,text,text) to authenticated;

-- Transaction-safe modification request ledger. The actual inventory mutation is performed only after a fresh quote/hold is available.
create table if not exists public.anaira_booking_modification_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.restaurants(id) on delete cascade,
  booking_id uuid not null references public.booking_reservations(id) on delete cascade,
  idempotency_key text not null,
  status text not null default 'requested',
  requested_check_in date,
  requested_check_out date,
  requested_room_type_id uuid,
  requested_rate_plan_id uuid,
  requested_adults integer,
  requested_children integer,
  quote jsonb not null default '{}'::jsonb,
  inventory_hold_id uuid,
  payment_adjustment numeric(14,2) not null default 0,
  reason text,
  actor_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id,idempotency_key)
);
create index if not exists anaira_booking_modification_idx on public.anaira_booking_modification_requests(tenant_id,booking_id,status,created_at desc);
alter table public.anaira_booking_modification_requests enable row level security;
drop policy if exists anaira_booking_modification_requests_tenant on public.anaira_booking_modification_requests;
create policy anaira_booking_modification_requests_tenant on public.anaira_booking_modification_requests
for all to authenticated using (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id());

create or replace function public.anaira_request_hotel_booking_modification(
  p_tenant_id uuid,p_booking_id uuid,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,
  p_adults integer default 2,p_children integer default 0,p_reason text default null,p_idempotency_key text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; q jsonb; req public.anaira_booking_modification_requests%rowtype; hold jsonb;
begin
  if p_idempotency_key is null then raise exception 'idempotency key is required'; end if;
  select * into req from public.anaira_booking_modification_requests where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key;
  if found then return jsonb_build_object('ok',true,'idempotent',true,'request_id',req.id,'status',req.status,'quote',req.quote); end if;
  select * into b from public.booking_reservations where id=p_booking_id and restaurant_id=p_tenant_id for update;
  if not found then raise exception 'Booking not found'; end if;
  if b.status not in ('confirmed','payment_pending') then raise exception 'Booking cannot be modified from status %',b.status; end if;
  if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
  q:=public.anaira_calculate_hotel_rate(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,null,'[]'::jsonb);
  hold:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,'mod:'||p_idempotency_key,p_booking_id,15);
  insert into public.anaira_booking_modification_requests(tenant_id,booking_id,idempotency_key,status,requested_check_in,requested_check_out,requested_room_type_id,requested_rate_plan_id,requested_adults,requested_children,quote,inventory_hold_id,payment_adjustment,reason,actor_id)
  values(p_tenant_id,p_booking_id,p_idempotency_key,'held',p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,q,(hold->>'hold_id')::uuid,(q->>'total')::numeric-coalesce(b.total_amount,0),p_reason,auth.uid()) returning * into req;
  return jsonb_build_object('ok',true,'request_id',req.id,'status',req.status,'quote',q,'payment_adjustment',req.payment_adjustment,'inventory_hold_id',req.inventory_hold_id);
end $$;
revoke execute on function public.anaira_request_hotel_booking_modification(uuid,uuid,date,date,uuid,uuid,integer,integer,text,text) from anon;
grant execute on function public.anaira_request_hotel_booking_modification(uuid,uuid,date,date,uuid,uuid,integer,integer,text,text) to authenticated;

-- Confirmation notification queue helper. Delivery is provider-backed; missing credentials become retryable failures.
create or replace function public.anaira_queue_booking_notification(p_booking_id uuid,p_event text,p_channel text default 'email') returns uuid
language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; nid uuid; recipient text;
begin
 select * into b from public.booking_reservations where id=p_booking_id;
 if not found then raise exception 'Booking not found'; end if;
 recipient:=case when lower(p_channel)='email' then b.guest_email else b.guest_phone end;
 if recipient is null or trim(recipient)='' then return null; end if;
 insert into public.anaira_notification_queue(restaurant_id,channel,recipient,template_key,subject,body,status,max_attempts,payload)
 values(b.restaurant_id,p_channel,recipient,'hotel.booking.'||p_event,'Booking '||p_event||' - '||b.booking_code,
   'Booking '||b.booking_code||' is now '||p_event||'.', 'queued',5,jsonb_build_object('booking_id',b.id,'event',p_event)) returning id into nid;
 return nid;
end $$;
grant execute on function public.anaira_queue_booking_notification(uuid,text,text) to authenticated;

-- Queue an email confirmation when a booking reaches confirmed status.
create or replace function public.anaira_booking_confirmation_notify() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if new.status='confirmed' and coalesce(old.status,'')<>new.status and nullif(trim(new.guest_email),'') is not null then
   perform public.anaira_queue_booking_notification(new.id,'confirmed','email');
 end if;
 return new;
end $$;
drop trigger if exists trg_anaira_booking_confirmation_notify on public.booking_reservations;
create trigger trg_anaira_booking_confirmation_notify after update of status on public.booking_reservations for each row execute function public.anaira_booking_confirmation_notify();

-- Reconciliation view: operational state vs payment state, no synthetic success.
create or replace view public.anaira_hotel_payment_reconciliation as
select b.id booking_id,b.restaurant_id,b.booking_code,b.status booking_status,b.payment_status,
       pi.id payment_intent_id,pi.status payment_intent_status,pi.provider,pi.provider_payment_id,
       pi.amount,coalesce(sum(r.amount) filter(where r.status='processed'),0) refunded_amount,
       (pi.amount-coalesce(sum(r.amount) filter(where r.status='processed'),0)) refundable_remaining
from public.booking_reservations b
left join public.anaira_payment_intents pi on pi.reference_type='hotel_booking' and pi.reference_id=b.id
left join public.anaira_payment_refunds r on r.payment_intent_id=pi.id
group by b.id,b.restaurant_id,b.booking_code,b.status,b.payment_status,pi.id,pi.status,pi.provider,pi.provider_payment_id,pi.amount;
