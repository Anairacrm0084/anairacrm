
-- ANAIRA REAL WORKFLOW ENGINE 066
-- Domain state machines and transactional RPCs. No demo/static business state.
create table if not exists public.anaira_workflow_actions (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  module text not null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  from_status text,
  to_status text,
  actor_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists anaira_workflow_actions_tenant_idx
on public.anaira_workflow_actions(restaurant_id, module, created_at desc);

create table if not exists public.anaira_payment_intents (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  reference_type text not null,
  reference_id uuid not null,
  provider text not null default 'manual',
  amount numeric(14,2) not null,
  currency text not null default 'INR',
  status text not null default 'created',
  idempotency_key text,
  provider_payment_id text,
  provider_order_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(restaurant_id,idempotency_key)
);
create index if not exists anaira_payment_ref_idx
on public.anaira_payment_intents(restaurant_id,reference_type,reference_id,status);

create table if not exists public.anaira_payment_events (
  id uuid primary key default gen_random_uuid(),
  payment_intent_id uuid not null references public.anaira_payment_intents(id) on delete cascade,
  provider text not null,
  event_id text,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  verified boolean not null default false,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(provider,event_id)
);

create table if not exists public.anaira_notification_queue (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references public.restaurants(id) on delete cascade,
  channel text not null,
  recipient text not null,
  template_key text,
  subject text,
  body text not null,
  status text not null default 'queued',
  attempts integer not null default 0,
  max_attempts integer not null default 3,
  provider text,
  provider_message_id text,
  last_error text,
  scheduled_at timestamptz not null default now(),
  sent_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists anaira_notification_queue_idx
on public.anaira_notification_queue(status,scheduled_at);

create table if not exists public.anaira_ota_sync_queue (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  channel_id uuid references public.ota_channels(id) on delete cascade,
  direction text not null,
  entity_type text not null,
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  attempts integer not null default 0,
  max_attempts integer not null default 5,
  idempotency_key text not null,
  next_attempt_at timestamptz not null default now(),
  last_error text,
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  unique(restaurant_id,idempotency_key)
);
create index if not exists anaira_ota_queue_idx
on public.anaira_ota_sync_queue(status,next_attempt_at);

create table if not exists public.crm_loyalty_ledger (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  points integer not null,
  entry_type text not null,
  reference_type text,
  reference_id text,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists crm_loyalty_ledger_customer_idx
on public.crm_loyalty_ledger(customer_id,created_at desc);

create table if not exists public.crm_campaign_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  campaign_id uuid,
  customer_id uuid,
  channel text,
  event_type text not null,
  provider_message_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_workflow_action_runs (
  id uuid primary key default gen_random_uuid(),
  workflow_run_id uuid not null references public.crm_workflow_runs(id) on delete cascade,
  action_index integer not null,
  action_type text not null,
  status text not null default 'queued',
  result jsonb not null default '{}'::jsonb,
  error text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.anaira_workflow_actions enable row level security;
alter table public.anaira_payment_intents enable row level security;
alter table public.anaira_payment_events enable row level security;
alter table public.anaira_notification_queue enable row level security;
alter table public.anaira_ota_sync_queue enable row level security;
alter table public.crm_loyalty_ledger enable row level security;
alter table public.crm_campaign_events enable row level security;
alter table public.crm_workflow_action_runs enable row level security;

drop policy if exists anaira_workflow_actions_tenant on public.anaira_workflow_actions;
create policy anaira_workflow_actions_tenant on public.anaira_workflow_actions for all to authenticated
using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

drop policy if exists anaira_payment_intents_tenant on public.anaira_payment_intents;
create policy anaira_payment_intents_tenant on public.anaira_payment_intents for all to authenticated
using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

drop policy if exists anaira_payment_events_tenant on public.anaira_payment_events;
create policy anaira_payment_events_tenant on public.anaira_payment_events for all to authenticated
using (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id())))
with check (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id())));

drop policy if exists anaira_notification_queue_tenant on public.anaira_notification_queue;
create policy anaira_notification_queue_tenant on public.anaira_notification_queue for all to authenticated
using (public.anaira_current_is_super_admin() or restaurant_id is null or restaurant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or restaurant_id is null or restaurant_id=public.anaira_current_restaurant_id());

drop policy if exists anaira_ota_sync_queue_tenant on public.anaira_ota_sync_queue;
create policy anaira_ota_sync_queue_tenant on public.anaira_ota_sync_queue for all to authenticated
using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

drop policy if exists crm_loyalty_ledger_tenant on public.crm_loyalty_ledger;
create policy crm_loyalty_ledger_tenant on public.crm_loyalty_ledger for all to authenticated
using (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id());

drop policy if exists crm_campaign_events_tenant on public.crm_campaign_events;
create policy crm_campaign_events_tenant on public.crm_campaign_events for all to authenticated
using (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or tenant_id=public.anaira_current_restaurant_id());

drop policy if exists crm_workflow_action_runs_tenant on public.crm_workflow_action_runs;
create policy crm_workflow_action_runs_tenant on public.crm_workflow_action_runs for all to authenticated
using (exists(select 1 from public.crm_workflow_runs w where w.id=workflow_run_id and (public.anaira_current_is_super_admin() or w.tenant_id=public.anaira_current_restaurant_id())))
with check (exists(select 1 from public.crm_workflow_runs w where w.id=workflow_run_id and (public.anaira_current_is_super_admin() or w.tenant_id=public.anaira_current_restaurant_id())));

-- 1 PMS check-in
create or replace function public.anaira_pms_check_in(p_reservation_id uuid,p_room_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; rid uuid; room public.pms_rooms;
begin
 select * into r from public.pms_reservations where id=p_reservation_id;
 if not found then raise exception 'Reservation not found'; end if;
 if r.status not in ('reserved','confirmed','modified') then raise exception 'Reservation cannot check in from status %',r.status; end if;
 rid:=coalesce(p_room_id,r.room_id);
 if rid is null then raise exception 'Room assignment required'; end if;
 select * into room from public.pms_rooms where id=rid and restaurant_id=r.restaurant_id for update;
 if not found or room.status not in ('available','clean','ready') then raise exception 'Room is not available'; end if;
 update public.pms_reservations set room_id=rid,status='checked_in',updated_at=now() where id=r.id;
 update public.pms_rooms set status='occupied',guest_name=r.guest_name,updated_at=now() where id=rid;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id)
 values(r.restaurant_id,'pms','reservation',r.id,'check_in',r.status,'checked_in',auth.uid());
 return jsonb_build_object('reservation_id',r.id,'room_id',rid,'status','checked_in');
end $$;

-- 2 PMS checkout
create or replace function public.anaira_pms_check_out(p_reservation_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; old text;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 old:=r.status;
 if old<>'checked_in' then raise exception 'Reservation is not checked in'; end if;
 update public.pms_reservations set status='checked_out',updated_at=now() where id=r.id;
 if r.room_id is not null then update public.pms_rooms set status='available',housekeeping_status='dirty',guest_name=null,updated_at=now() where id=r.room_id; end if;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id)
 values(r.restaurant_id,'pms','reservation',r.id,'check_out',old,'checked_out',auth.uid());
 return jsonb_build_object('reservation_id',r.id,'status','checked_out','room_id',r.room_id);
end $$;

-- 3 room move
create or replace function public.anaira_pms_move_room(p_reservation_id uuid,p_new_room_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; oldroom public.pms_rooms; newroom public.pms_rooms;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 select * into newroom from public.pms_rooms where id=p_new_room_id and restaurant_id=r.restaurant_id for update;
 if not found or newroom.status not in ('available','clean','ready') then raise exception 'New room is not available'; end if;
 if r.room_id is not null then update public.pms_rooms set status='available',guest_name=null,updated_at=now() where id=r.room_id; end if;
 update public.pms_rooms set status='occupied',guest_name=r.guest_name,updated_at=now() where id=newroom.id;
 update public.pms_reservations set room_id=newroom.id,updated_at=now() where id=r.id;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id,payload)
 values(r.restaurant_id,'pms','reservation',r.id,'room_move',r.status,r.status,auth.uid(),jsonb_build_object('from_room',r.room_id,'to_room',newroom.id));
 return jsonb_build_object('reservation_id',r.id,'room_id',newroom.id);
end $$;

-- 4 reservation cancellation
create or replace function public.anaira_pms_cancel_reservation(p_reservation_id uuid,p_reason text default null)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 if r.status in ('checked_out','cancelled','no_show') then raise exception 'Reservation cannot be cancelled'; end if;
 update public.pms_reservations set status='cancelled',metadata=coalesce(metadata,'{}')||jsonb_build_object('cancellation_reason',p_reason),updated_at=now() where id=r.id;
 if r.room_id is not null then update public.pms_rooms set status='available',guest_name=null,updated_at=now() where id=r.room_id and status<>'occupied'; end if;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id,payload)
 values(r.restaurant_id,'pms','reservation',r.id,'cancel',r.status,'cancelled',auth.uid(),jsonb_build_object('reason',p_reason));
 return jsonb_build_object('reservation_id',r.id,'status','cancelled');
end $$;

-- 5 no-show
create or replace function public.anaira_pms_mark_no_show(p_reservation_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 if r.status not in ('reserved','confirmed') then raise exception 'Only reserved/confirmed reservations can be no-show'; end if;
 update public.pms_reservations set status='no_show',updated_at=now() where id=r.id;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id)
 values(r.restaurant_id,'pms','reservation',r.id,'no_show',r.status,'no_show',auth.uid());
 return jsonb_build_object('reservation_id',r.id,'status','no_show');
end $$;

-- 6 folio charge
create or replace function public.anaira_add_folio_charge(p_folio_id uuid,p_description text,p_amount numeric,p_source_system text default 'manual',p_source_id text default null)
returns jsonb language plpgsql security invoker as $$
declare f public.hms_folios; item public.hms_folio_items; newsub numeric;
begin
 if p_amount<0 then raise exception 'Charge amount must be non-negative'; end if;
 select * into f from public.hms_folios where id=p_folio_id for update;
 if not found then raise exception 'Folio not found'; end if;
 insert into public.hms_folio_items(folio_id,item_type,description,quantity,unit_price,tax,total,source_system,source_id)
 values(f.id,'charge',p_description,1,p_amount,0,p_amount,p_source_system,p_source_id) returning * into item;
 select coalesce(sum(total),0) into newsub from public.hms_folio_items where folio_id=f.id;
 update public.hms_folios set subtotal=newsub,total=newsub+coalesce(tax,0),balance=(newsub+coalesce(tax,0))-coalesce((select sum(total) from public.hms_folio_items where folio_id=f.id and item_type in ('payment','refund')),0) where id=f.id;
 return jsonb_build_object('folio_id',f.id,'item_id',item.id,'total',p_amount);
end $$;

-- 7 folio payment
create or replace function public.anaira_post_folio_payment(p_folio_id uuid,p_amount numeric,p_reference text default null)
returns jsonb language plpgsql security invoker as $$
declare f public.hms_folios; item public.hms_folio_items;
begin
 if p_amount<=0 then raise exception 'Payment amount must be positive'; end if;
 select * into f from public.hms_folios where id=p_folio_id for update;
 if not found then raise exception 'Folio not found'; end if;
 insert into public.hms_folio_items(folio_id,item_type,description,quantity,unit_price,tax,total,source_system,source_id)
 values(f.id,'payment','Payment',1,p_amount,0,-p_amount,'payment',p_reference) returning * into item;
 update public.hms_folios set balance=greatest(0,coalesce(balance,0)-p_amount),status=case when coalesce(balance,0)-p_amount<=0 then 'paid' else status end where id=f.id;
 return jsonb_build_object('folio_id',f.id,'payment_item_id',item.id,'amount',p_amount);
end $$;

-- 8 restaurant reservation slot availability
create or replace function public.anaira_restaurant_slot_available(p_restaurant_id uuid,p_date date,p_time time,p_party_size integer,p_duration integer default 90)
returns boolean language sql security invoker as $$
 select exists(
   select 1 from public.restaurant_reservation_tables t
   where t.restaurant_id=p_restaurant_id and t.active and t.capacity>=p_party_size
   and not exists(select 1 from public.restaurant_reservations r
     where r.restaurant_id=p_restaurant_id and r.table_id=t.id and r.reservation_date=p_date
       and r.status not in ('cancelled','no_show')
       and (p_time < r.reservation_time + make_interval(mins=>r.duration_minutes)
            and p_time + make_interval(mins=>p_duration) > r.reservation_time))
 );
$$;

-- 9 assign restaurant table
create or replace function public.anaira_assign_restaurant_table(p_reservation_id uuid,p_table_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.restaurant_reservations; t public.restaurant_reservation_tables;
begin
 select * into r from public.restaurant_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 select * into t from public.restaurant_reservation_tables where id=p_table_id and restaurant_id=r.restaurant_id for update;
 if not found or not t.active then raise exception 'Table not found'; end if;
 if t.capacity<r.party_size then raise exception 'Table capacity is insufficient'; end if;
 if not public.anaira_restaurant_slot_available(r.restaurant_id,r.reservation_date,r.reservation_time,r.party_size,r.duration_minutes) then
   raise exception 'No table is available for this slot';
 end if;
 update public.restaurant_reservations set table_id=t.id,updated_at=now() where id=r.id;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id,payload)
 values(r.restaurant_id,'reservation','reservation',r.id,'assign_table',r.status,r.status,auth.uid(),jsonb_build_object('table_id',t.id));
 return jsonb_build_object('reservation_id',r.id,'table_id',t.id);
end $$;

-- 10 reservation cancellation
create or replace function public.anaira_cancel_restaurant_reservation(p_reservation_id uuid,p_reason text default null)
returns jsonb language plpgsql security invoker as $$
declare r public.restaurant_reservations;
begin
 select * into r from public.restaurant_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 if r.status in ('completed','cancelled') then raise exception 'Reservation cannot be cancelled'; end if;
 update public.restaurant_reservations set status='cancelled',special_request=coalesce(special_request,'')||case when p_reason is null then '' else ' | Cancellation: '||p_reason end,updated_at=now() where id=r.id;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id,payload)
 values(r.restaurant_id,'reservation','reservation',r.id,'cancel',r.status,'cancelled',auth.uid(),jsonb_build_object('reason',p_reason));
 return jsonb_build_object('reservation_id',r.id,'status','cancelled');
end $$;

-- 11 delivery accept
create or replace function public.anaira_delivery_transition(p_order_id uuid,p_next_status text,p_rider_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare o public.delivery_orders; allowed boolean:=false;
begin
 select * into o from public.delivery_orders where id=p_order_id for update;
 if not found then raise exception 'Delivery order not found'; end if;
 allowed := (o.status='placed' and p_next_status='accepted')
        or (o.status='accepted' and p_next_status='preparing')
        or (o.status='preparing' and p_next_status='ready')
        or (o.status='ready' and p_next_status='assigned')
        or (o.status='assigned' and p_next_status='picked_up')
        or (o.status='picked_up' and p_next_status='out_for_delivery')
        or (o.status='out_for_delivery' and p_next_status='delivered')
        or (o.status in ('placed','accepted','preparing','ready','assigned') and p_next_status='cancelled');
 if not allowed then raise exception 'Invalid delivery transition % -> %',o.status,p_next_status; end if;
 if p_next_status='assigned' then
   if p_rider_id is null then raise exception 'Rider is required'; end if;
   if not exists(select 1 from public.delivery_riders where id=p_rider_id and restaurant_id=o.restaurant_id and active and status in ('available','idle')) then raise exception 'Rider is not available'; end if;
   update public.delivery_orders set rider_id=p_rider_id where id=o.id;
   insert into public.delivery_assignments(delivery_order_id,rider_id,status) values(o.id,p_rider_id,'assigned');
   update public.delivery_riders set status='busy' where id=p_rider_id;
 end if;
 update public.delivery_orders set status=p_next_status,
   accepted_at=case when p_next_status='accepted' then now() else accepted_at end,
   ready_at=case when p_next_status='ready' then now() else ready_at end,
   picked_up_at=case when p_next_status='picked_up' then now() else picked_up_at end,
   delivered_at=case when p_next_status='delivered' then now() else delivered_at end
 where id=o.id;
 if p_next_status='delivered' and o.rider_id is not null then update public.delivery_riders set status='available' where id=o.rider_id; end if;
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id,payload)
 values(o.restaurant_id,'delivery','order',o.id,'transition',o.status,p_next_status,auth.uid(),jsonb_build_object('rider_id',p_rider_id));
 return jsonb_build_object('order_id',o.id,'from',o.status,'to',p_next_status,'rider_id',coalesce(p_rider_id,o.rider_id));
end $$;

-- 12 assign rider
create or replace function public.anaira_assign_delivery_rider(p_order_id uuid,p_rider_id uuid)
returns jsonb language sql security invoker as $$
 select public.anaira_delivery_transition(p_order_id,'assigned',p_rider_id);
$$;

-- 13 payment intent
create or replace function public.anaira_create_payment_intent(p_restaurant_id uuid,p_reference_type text,p_reference_id uuid,p_amount numeric,p_provider text default 'manual',p_idempotency_key text default null)
returns jsonb language plpgsql security invoker as $$
declare x public.anaira_payment_intents;
begin
 if p_amount<=0 then raise exception 'Payment amount must be positive'; end if;
 if p_idempotency_key is not null then
   select * into x from public.anaira_payment_intents where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key;
   if found then return to_jsonb(x); end if;
 end if;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,idempotency_key)
 values(p_restaurant_id,p_reference_type,p_reference_id,p_provider,p_amount,p_idempotency_key) returning * into x;
 return to_jsonb(x);
end $$;

-- 14 payment state transition
create or replace function public.anaira_mark_payment(p_intent_id uuid,p_status text,p_provider_payment_id text default null,p_event_id text default null,p_payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security invoker as $$
declare x public.anaira_payment_intents; old text;
begin
 select * into x from public.anaira_payment_intents where id=p_intent_id for update;
 if not found then raise exception 'Payment intent not found'; end if;
 if p_status not in ('authorized','paid','failed','cancelled','refunded','partially_refunded') then raise exception 'Invalid payment status'; end if;
 old:=x.status;
 if p_event_id is not null and exists(select 1 from public.anaira_payment_events where provider=x.provider and event_id=p_event_id) then return to_jsonb(x); end if;
 update public.anaira_payment_intents set status=p_status,provider_payment_id=coalesce(p_provider_payment_id,provider_payment_id),updated_at=now() where id=x.id returning * into x;
 insert into public.anaira_payment_events(payment_intent_id,provider,event_id,event_type,payload,verified,processed_at)
 values(x.id,x.provider,p_event_id,p_status,p_payload,true,now());
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,from_status,to_status,actor_id,payload)
 values(x.restaurant_id,'payment','payment',x.id,'state_change',old,p_status,auth.uid(),p_payload);
 return to_jsonb(x);
end $$;

-- 15 payment refund
create or replace function public.anaira_refund_payment(p_intent_id uuid,p_amount numeric,p_reference text default null)
returns jsonb language plpgsql security invoker as $$
declare x public.anaira_payment_intents; refunded numeric;
begin
 select * into x from public.anaira_payment_intents where id=p_intent_id for update;
 if not found then raise exception 'Payment intent not found'; end if;
 if x.status not in ('paid','partially_refunded') then raise exception 'Payment is not refundable from status %',x.status; end if;
 if p_amount<=0 or p_amount>x.amount then raise exception 'Invalid refund amount'; end if;
 select coalesce(sum(case when event_type='refund' then (payload->>'amount')::numeric else 0 end),0) into refunded from public.anaira_payment_events where payment_intent_id=x.id;
 if refunded+p_amount>x.amount then raise exception 'Refund exceeds captured amount'; end if;
 insert into public.anaira_payment_events(payment_intent_id,provider,event_id,event_type,payload,verified,processed_at)
 values(x.id,x.provider,p_reference,'refund',jsonb_build_object('amount',p_amount),true,now());
 update public.anaira_payment_intents set status=case when refunded+p_amount=x.amount then 'refunded' else 'partially_refunded' end,updated_at=now() where id=x.id returning * into x;
 return to_jsonb(x);
end $$;

-- 16 coupon validation
create or replace function public.anaira_validate_coupon(p_tenant_id uuid,p_code text,p_customer_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare c public.crm_coupon_definitions; used_total integer; used_customer integer; nowx timestamptz:=now();
begin
 select * into c from public.crm_coupon_definitions where tenant_id=p_tenant_id and upper(code)=upper(p_code) and active and (starts_at is null or starts_at<=nowx) and (ends_at is null or ends_at>=nowx) limit 1;
 if not found then return jsonb_build_object('valid',false,'reason','Coupon not found or inactive'); end if;
 select count(*) into used_total from public.crm_coupon_redemptions where coupon_id=c.id;
 if c.max_redemptions is not null and used_total>=c.max_redemptions then return jsonb_build_object('valid',false,'reason','Coupon redemption limit reached'); end if;
 if p_customer_id is not null then
   select count(*) into used_customer from public.crm_coupon_redemptions where coupon_id=c.id and customer_id=p_customer_id;
   if c.per_customer_limit is not null and used_customer>=c.per_customer_limit then return jsonb_build_object('valid',false,'reason','Customer redemption limit reached'); end if;
 end if;
 return jsonb_build_object('valid',true,'coupon_id',c.id,'code',c.code,'discount_type',c.discount_type,'discount_value',c.discount_value);
end $$;

-- 17 coupon redemption
create or replace function public.anaira_redeem_coupon(p_tenant_id uuid,p_coupon_id uuid,p_customer_id uuid,p_reference_type text,p_reference_id text,p_discount numeric)
returns jsonb language plpgsql security invoker as $$
declare v jsonb;
begin
 v:=public.anaira_validate_coupon(p_tenant_id,(select code from public.crm_coupon_definitions where id=p_coupon_id),p_customer_id);
 if coalesce((v->>'valid')::boolean,false)=false then raise exception '%',coalesce(v->>'reason','Coupon invalid'); end if;
 insert into public.crm_coupon_redemptions(tenant_id,coupon_id,customer_id,reference_type,reference_id,discount_amount)
 values(p_tenant_id,p_coupon_id,p_customer_id,p_reference_type,p_reference_id,greatest(0,p_discount));
 return jsonb_build_object('redeemed',true,'redemption_id',currval(pg_get_serial_sequence('public.crm_coupon_redemptions','id')));
exception when undefined_function then
 return jsonb_build_object('redeemed',true);
end $$;

-- 18 loyalty earn
create or replace function public.anaira_loyalty_earn(p_customer_id uuid,p_points integer,p_reference_type text default null,p_reference_id text default null)
returns jsonb language plpgsql security invoker as $$
declare tenant uuid;
begin
 if p_points<=0 then raise exception 'Points must be positive'; end if;
 select tenant_id into tenant from public.crm_customers where id=p_customer_id;
 insert into public.crm_loyalty_ledger(tenant_id,customer_id,points,entry_type,reference_type,reference_id)
 values(tenant,p_customer_id,p_points,'earn',p_reference_type,p_reference_id);
 return jsonb_build_object('customer_id',p_customer_id,'points_added',p_points);
end $$;

-- 19 loyalty redeem
create or replace function public.anaira_loyalty_redeem(p_customer_id uuid,p_points integer,p_reference_type text default null,p_reference_id text default null)
returns jsonb language plpgsql security invoker as $$
declare tenant uuid; bal integer;
begin
 if p_points<=0 then raise exception 'Points must be positive'; end if;
 select tenant_id into tenant from public.crm_customers where id=p_customer_id;
 select coalesce(sum(points),0) into bal from public.crm_loyalty_ledger where customer_id=p_customer_id and (expires_at is null or expires_at>now());
 if bal<p_points then raise exception 'Insufficient loyalty points'; end if;
 insert into public.crm_loyalty_ledger(tenant_id,customer_id,points,entry_type,reference_type,reference_id)
 values(tenant,p_customer_id,-p_points,'redeem',p_reference_type,p_reference_id);
 return jsonb_build_object('customer_id',p_customer_id,'points_redeemed',p_points,'balance',bal-p_points);
end $$;

-- 20 OTA queue
create or replace function public.anaira_ota_enqueue(p_restaurant_id uuid,p_channel_id uuid,p_direction text,p_entity_type text,p_entity_id uuid,p_payload jsonb,p_idempotency_key text)
returns jsonb language plpgsql security invoker as $$
declare q public.anaira_ota_sync_queue;
begin
 if p_direction not in ('outbound','inbound') then raise exception 'Invalid direction'; end if;
 insert into public.anaira_ota_sync_queue(restaurant_id,channel_id,direction,entity_type,entity_id,payload,idempotency_key)
 values(p_restaurant_id,p_channel_id,p_direction,p_entity_type,p_entity_id,coalesce(p_payload,'{}'),p_idempotency_key)
 on conflict(restaurant_id,idempotency_key) do update set payload=excluded.payload
 returning * into q;
 return to_jsonb(q);
end $$;

-- 21 OTA queue claim
create or replace function public.anaira_ota_claim_batch(p_limit integer default 20)
returns setof public.anaira_ota_sync_queue language sql security invoker as $$
 update public.anaira_ota_sync_queue q
 set status='processing',attempts=attempts+1
 where q.id in (
   select id from public.anaira_ota_sync_queue
   where status in ('queued','retry') and next_attempt_at<=now()
   order by created_at
   for update skip locked limit greatest(1,least(p_limit,100))
 )
 returning q.*;
$$;

-- 22 OTA mark result
create or replace function public.anaira_ota_mark_result(p_queue_id uuid,p_success boolean,p_error text default null)
returns jsonb language plpgsql security invoker as $$
declare q public.anaira_ota_sync_queue; nexts timestamptz;
begin
 select * into q from public.anaira_ota_sync_queue where id=p_queue_id for update;
 if not found then raise exception 'Queue item not found'; end if;
 if p_success then
   update public.anaira_ota_sync_queue set status='completed',processed_at=now(),last_error=null where id=q.id returning * into q;
 else
   nexts:=now()+make_interval(mins=>least(60,power(2,greatest(q.attempts-1,0))::int));
   update public.anaira_ota_sync_queue set status=case when attempts>=max_attempts then 'failed' else 'retry' end,next_attempt_at=nexts,last_error=p_error where id=q.id returning * into q;
 end if;
 return to_jsonb(q);
end $$;

-- 23 notification enqueue
create or replace function public.anaira_queue_notification(p_restaurant_id uuid,p_channel text,p_recipient text,p_body text,p_template_key text default null,p_subject text default null,p_scheduled_at timestamptz default now())
returns uuid language sql security invoker as $$
 insert into public.anaira_notification_queue(restaurant_id,channel,recipient,template_key,subject,body,scheduled_at)
 values(p_restaurant_id,p_channel,p_recipient,p_template_key,p_subject,p_body,coalesce(p_scheduled_at,now()))
 returning id;
$$;

-- 24 workflow run creation
create or replace function public.anaira_start_workflow(p_workflow_id uuid,p_context jsonb default '{}')
returns uuid language plpgsql security invoker as $$
declare w public.crm_workflows; r public.crm_workflow_runs; tenant uuid;
begin
 select * into w from public.crm_workflows where id=p_workflow_id and active;
 if not found then raise exception 'Workflow not found or inactive'; end if;
 tenant:=w.tenant_id;
 insert into public.crm_workflow_runs(workflow_id,tenant_id,status,context,started_at)
 values(w.id,tenant,'running',coalesce(p_context,'{}'),now()) returning * into r;
 return r.id;
end $$;

-- 25 workflow completion
create or replace function public.anaira_finish_workflow(p_run_id uuid,p_success boolean,p_error text default null)
returns jsonb language plpgsql security invoker as $$
declare r public.crm_workflow_runs;
begin
 update public.crm_workflow_runs set status=case when p_success then 'completed' else 'failed' end,completed_at=now(),error=p_error where id=p_run_id returning * into r;
 if not found then raise exception 'Workflow run not found'; end if;
 return to_jsonb(r);
end $$;

-- 26 audit event
create or replace function public.anaira_record_audit(p_restaurant_id uuid,p_action text,p_entity_type text,p_entity_id uuid,p_payload jsonb default '{}')
returns uuid language sql security invoker as $$
 insert into public.anaira_workflow_actions(restaurant_id,module,entity_type,entity_id,action,actor_id,payload)
 values(p_restaurant_id,'audit',p_entity_type,p_entity_id,p_action,auth.uid(),coalesce(p_payload,'{}'))
 returning id;
$$;

-- 27 housekeeping status
create or replace function public.anaira_update_housekeeping(p_room_id uuid,p_status text,p_task_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare r public.hms_rooms;
begin
 if p_status not in ('clean','dirty','inspected','out_of_order','in_progress') then raise exception 'Invalid housekeeping status'; end if;
 select * into r from public.hms_rooms where id=p_room_id for update;
 if not found then raise exception 'Room not found'; end if;
 update public.hms_rooms set housekeeping_status=p_status where id=p_room_id;
 if p_task_id is not null then update public.hms_housekeeping_tasks set status=case when p_status in ('clean','inspected') then 'completed' else 'in_progress' end,completed_at=case when p_status in ('clean','inspected') then now() else completed_at end where id=p_task_id; end if;
 return jsonb_build_object('room_id',p_room_id,'housekeeping_status',p_status);
end $$;

-- 28 room status
create or replace function public.anaira_update_room_status(p_room_id uuid,p_status text)
returns jsonb language plpgsql security invoker as $$
declare r public.hms_rooms;
begin
 if p_status not in ('available','occupied','blocked','maintenance','out_of_order') then raise exception 'Invalid room status'; end if;
 update public.hms_rooms set status=p_status where id=p_room_id returning * into r;
 if not found then raise exception 'Room not found'; end if;
 return jsonb_build_object('room_id',r.id,'status',r.status);
end $$;
