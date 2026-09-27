-- ANAIRA 067: Real workflow/integration contracts
-- This migration intentionally creates integration-ready primitives. Provider credentials are never stored here.

create table if not exists public.anaira_workflow_events (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 module text not null, entity_type text not null, entity_id uuid not null, event_type text not null,
 from_status text, to_status text, actor_id uuid, payload jsonb not null default '{}'::jsonb,
 request_id text, created_at timestamptz not null default now()
);
create index if not exists anaira_workflow_events_entity_idx on public.anaira_workflow_events(restaurant_id,module,entity_type,entity_id,created_at desc);

create table if not exists public.anaira_payment_intents (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 reference_type text not null, reference_id uuid not null, provider text not null,
 amount numeric(14,2) not null check(amount > 0), currency text not null default 'INR',
 status text not null default 'created' check(status in ('created','pending','authorized','paid','failed','cancelled','partially_refunded','refunded')),
 idempotency_key text, provider_order_id text, provider_payment_id text, metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(restaurant_id,idempotency_key)
);
create table if not exists public.anaira_payment_events (
 id uuid primary key default gen_random_uuid(), payment_intent_id uuid not null references public.anaira_payment_intents(id) on delete cascade,
 provider text not null, event_id text, event_type text not null, payload jsonb not null default '{}'::jsonb,
 signature_verified boolean not null default false, processed_at timestamptz, created_at timestamptz not null default now(),
 unique(provider,event_id)
);
create table if not exists public.anaira_payment_refunds (
 id uuid primary key default gen_random_uuid(), payment_intent_id uuid not null references public.anaira_payment_intents(id) on delete cascade,
 amount numeric(14,2) not null check(amount > 0), status text not null default 'requested', provider_refund_id text,
 reason text, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.anaira_integration_health (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 provider text not null, integration_type text not null, status text not null default 'not_configured',
 last_checked_at timestamptz, last_success_at timestamptz, last_error text, capabilities jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(restaurant_id,provider,integration_type)
);

create table if not exists public.anaira_ota_sync_queue (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 provider text not null, direction text not null check(direction in ('outbound','inbound')),
 event_type text not null, entity_type text not null, entity_id uuid, payload jsonb not null default '{}'::jsonb,
 status text not null default 'pending' check(status in ('pending','processing','succeeded','failed','dead_letter')),
 attempts integer not null default 0, next_attempt_at timestamptz not null default now(), last_error text,
 idempotency_key text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(provider,idempotency_key)
);

create table if not exists public.anaira_notification_queue (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 channel text not null check(channel in ('email','sms','whatsapp','push')), provider text, recipient text not null,
 template_key text not null, payload jsonb not null default '{}'::jsonb,
 status text not null default 'pending' check(status in ('pending','processing','sent','failed','cancelled')),
 attempts integer not null default 0, next_attempt_at timestamptz not null default now(), provider_message_id text, last_error text,
 created_at timestamptz not null default now(), sent_at timestamptz
);

create table if not exists public.anaira_workflow_runs (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 workflow_key text not null, trigger_type text not null, entity_type text, entity_id uuid,
 status text not null default 'queued' check(status in ('queued','running','succeeded','failed','cancelled')),
 input jsonb not null default '{}'::jsonb, output jsonb not null default '{}'::jsonb, error text,
 attempts integer not null default 0, created_at timestamptz not null default now(), started_at timestamptz, finished_at timestamptz
);

create table if not exists public.anaira_loyalty_ledger (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 customer_id uuid not null, points integer not null, entry_type text not null,
 reference_type text, reference_id uuid, expires_at timestamptz, created_at timestamptz not null default now()
);
create index if not exists anaira_loyalty_ledger_customer_idx on public.anaira_loyalty_ledger(restaurant_id,customer_id,created_at desc);

alter table public.anaira_workflow_events enable row level security;
alter table public.anaira_payment_intents enable row level security;
alter table public.anaira_payment_events enable row level security;
alter table public.anaira_payment_refunds enable row level security;
alter table public.anaira_integration_health enable row level security;
alter table public.anaira_ota_sync_queue enable row level security;
alter table public.anaira_notification_queue enable row level security;
alter table public.anaira_workflow_runs enable row level security;
alter table public.anaira_loyalty_ledger enable row level security;



create or replace function public.anaira_log_workflow_event(p_restaurant_id uuid,p_module text,p_entity_type text,p_entity_id uuid,p_event_type text,p_from text,p_to text,p_payload jsonb default '{}'::jsonb)
returns uuid language plpgsql security invoker as $$
declare v_id uuid;
begin
 insert into public.anaira_workflow_events(restaurant_id,module,entity_type,entity_id,event_type,from_status,to_status,actor_id,payload)
 values(p_restaurant_id,p_module,p_entity_type,p_entity_id,p_event_type,p_from,p_to,auth.uid(),coalesce(p_payload,'{}')) returning id into v_id;
 return v_id;
end $$;

create or replace function public.anaira_delivery_transition(p_order_id uuid,p_next_status text,p_rider_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare o public.delivery_orders; r public.delivery_riders; old_status text;
begin
 select * into o from public.delivery_orders where id=p_order_id for update;
 if not found then raise exception 'Delivery order not found'; end if;
 old_status:=o.status;
 if p_next_status not in ('accepted','preparing','ready','assigned','picked_up','out_for_delivery','delivered','cancelled') then raise exception 'Invalid delivery status'; end if;
 if not ((old_status='placed' and p_next_status='accepted') or (old_status='accepted' and p_next_status='preparing') or (old_status='preparing' and p_next_status='ready') or (old_status='ready' and p_next_status='assigned') or (old_status='assigned' and p_next_status='picked_up') or (old_status='picked_up' and p_next_status='out_for_delivery') or (old_status='out_for_delivery' and p_next_status='delivered') or (p_next_status='cancelled' and old_status not in ('delivered','cancelled'))) then raise exception 'Invalid transition % -> %',old_status,p_next_status; end if;
 if p_next_status='assigned' then
   if p_rider_id is null then raise exception 'Rider required'; end if;
   select * into r from public.delivery_riders where id=p_rider_id and restaurant_id=o.restaurant_id and active=true for update;
   if not found or r.status not in ('available','idle') then raise exception 'Rider unavailable'; end if;
   update public.delivery_orders set rider_id=p_rider_id where id=o.id;
   insert into public.delivery_assignments(delivery_order_id,rider_id,status,assigned_at) values(o.id,p_rider_id,'assigned',now());
   update public.delivery_riders set status='busy' where id=r.id;
 end if;
 update public.delivery_orders set status=p_next_status,
 accepted_at=case when p_next_status='accepted' then now() else accepted_at end,
 ready_at=case when p_next_status='ready' then now() else ready_at end,
 picked_up_at=case when p_next_status='picked_up' then now() else picked_up_at end,
 delivered_at=case when p_next_status='delivered' then now() else delivered_at end
 where id=o.id;
 if p_next_status='delivered' and o.rider_id is not null then update public.delivery_riders set status='available' where id=o.rider_id; end if;
 perform public.anaira_log_workflow_event(o.restaurant_id,'delivery','delivery_order',o.id,'status_changed',old_status,p_next_status,jsonb_build_object('rider_id',coalesce(p_rider_id,o.rider_id)));
 return jsonb_build_object('id',o.id,'from',old_status,'to',p_next_status);
end $$;

create or replace function public.anaira_pms_check_in(p_reservation_id uuid,p_room_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; room public.pms_rooms; rid uuid; old_status text;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 old_status:=r.status; rid:=coalesce(p_room_id,r.room_id);
 if old_status not in ('reserved','confirmed','modified') then raise exception 'Reservation cannot check in from %',old_status; end if;
 if rid is null then raise exception 'Room assignment required'; end if;
 select * into room from public.pms_rooms where id=rid and restaurant_id=r.restaurant_id for update;
 if not found or room.status not in ('available','clean','ready') then raise exception 'Room not available'; end if;
 update public.pms_reservations set room_id=rid,status='checked_in',updated_at=now() where id=r.id;
 update public.pms_rooms set status='occupied',guest_name=r.guest_name,reservation_id=r.id,updated_at=now() where id=rid;
 perform public.anaira_log_workflow_event(r.restaurant_id,'pms','reservation',r.id,'check_in',old_status,'checked_in',jsonb_build_object('room_id',rid));
 return jsonb_build_object('reservation_id',r.id,'room_id',rid,'status','checked_in');
end $$;

create or replace function public.anaira_pms_check_out(p_reservation_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; old_status text;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 old_status:=r.status; if old_status<>'checked_in' then raise exception 'Reservation is not checked in'; end if;
 update public.pms_reservations set status='checked_out',updated_at=now() where id=r.id;
 if r.room_id is not null then update public.pms_rooms set status='available',housekeeping_status='dirty',guest_name=null,reservation_id=null,updated_at=now() where id=r.room_id; end if;
 perform public.anaira_log_workflow_event(r.restaurant_id,'pms','reservation',r.id,'check_out',old_status,'checked_out',jsonb_build_object('room_id',r.room_id));
 return jsonb_build_object('reservation_id',r.id,'status','checked_out');
end $$;

create or replace function public.anaira_pms_move_room(p_reservation_id uuid,p_new_room_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; nr public.pms_rooms; old_room uuid;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 select * into nr from public.pms_rooms where id=p_new_room_id and restaurant_id=r.restaurant_id for update;
 if not found or nr.status not in ('available','clean','ready') then raise exception 'New room not available'; end if;
 old_room:=r.room_id;
 if old_room is not null then update public.pms_rooms set status='available',guest_name=null,reservation_id=null,updated_at=now() where id=old_room; end if;
 update public.pms_rooms set status=case when r.status='checked_in' then 'occupied' else 'reserved' end,guest_name=r.guest_name,reservation_id=r.id,updated_at=now() where id=nr.id;
 update public.pms_reservations set room_id=nr.id,updated_at=now() where id=r.id;
 perform public.anaira_log_workflow_event(r.restaurant_id,'pms','reservation',r.id,'room_moved',null,null,jsonb_build_object('old_room_id',old_room,'new_room_id',nr.id));
 return jsonb_build_object('reservation_id',r.id,'old_room_id',old_room,'new_room_id',nr.id);
end $$;

create or replace function public.anaira_pms_mark_no_show(p_reservation_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; old_status text;
begin
 select * into r from public.pms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 old_status:=r.status; if old_status not in ('reserved','confirmed','modified') then raise exception 'Cannot mark no-show from %',old_status; end if;
 update public.pms_reservations set status='no_show',updated_at=now() where id=r.id;
 if r.room_id is not null then update public.pms_rooms set status='available',guest_name=null,reservation_id=null,updated_at=now() where id=r.room_id and status<>'occupied'; end if;
 perform public.anaira_log_workflow_event(r.restaurant_id,'pms','reservation',r.id,'no_show',old_status,'no_show');
 return jsonb_build_object('reservation_id',r.id,'status','no_show');
end $$;

create or replace function public.anaira_create_payment_intent(p_restaurant_id uuid,p_reference_type text,p_reference_id uuid,p_amount numeric,p_provider text,p_idempotency_key text default null)
returns jsonb language plpgsql security invoker as $$
declare x public.anaira_payment_intents;
begin
 if p_amount<=0 then raise exception 'Amount must be positive'; end if;
 if p_idempotency_key is not null then select * into x from public.anaira_payment_intents where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key; if found then return to_jsonb(x); end if; end if;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,status,idempotency_key) values(p_restaurant_id,p_reference_type,p_reference_id,p_provider,p_amount,'created',p_idempotency_key) returning * into x;
 return to_jsonb(x);
end $$;

create or replace function public.anaira_mark_payment(p_intent_id uuid,p_status text,p_provider_payment_id text default null,p_event_id text default null,p_payload jsonb default '{}'::jsonb,p_signature_verified boolean default false)
returns jsonb language plpgsql security invoker as $$
declare x public.anaira_payment_intents;
begin
 select * into x from public.anaira_payment_intents where id=p_intent_id for update;
 if not found then raise exception 'Payment intent not found'; end if;
 if p_status not in ('authorized','paid','failed','cancelled','partially_refunded','refunded') then raise exception 'Invalid payment status'; end if;
 if p_status='paid' and not p_signature_verified then raise exception 'Paid status requires verified provider webhook'; end if;
 if p_event_id is not null and exists(select 1 from public.anaira_payment_events where provider=x.provider and event_id=p_event_id) then return to_jsonb(x); end if;
 update public.anaira_payment_intents set status=p_status,provider_payment_id=coalesce(p_provider_payment_id,provider_payment_id),updated_at=now() where id=x.id returning * into x;
 insert into public.anaira_payment_events(payment_intent_id,provider,event_id,event_type,payload,signature_verified,processed_at) values(x.id,x.provider,p_event_id,p_status,coalesce(p_payload,'{}'),p_signature_verified,now());
 return to_jsonb(x);
end $$;

-- RLS for new tables. Tenant isolation follows the existing canonical helper.
DO $$ declare t text; begin
 foreach t in array array['anaira_workflow_events','anaira_payment_intents','anaira_payment_refunds','anaira_integration_health','anaira_ota_sync_queue','anaira_notification_queue','anaira_workflow_runs','anaira_loyalty_ledger'] loop
   execute format('drop policy if exists %I_tenant on public.%I',t,t);
   execute format('create policy %I_tenant on public.%I for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())',t,t);
 end loop;
end $$;
create policy anaira_payment_events_tenant on public.anaira_payment_events for all to authenticated
using (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id())))
with check (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id())));

create or replace function public.anaira_restaurant_slot_available(p_restaurant_id uuid,p_date date,p_time time,p_party_size integer,p_duration_minutes integer default 90)
returns jsonb language plpgsql security invoker as $$
declare available_tables integer;
begin
 select count(*) into available_tables
 from public.restaurant_reservation_tables t
 where t.restaurant_id=p_restaurant_id and t.active=true and t.capacity>=p_party_size
 and not exists(select 1 from public.restaurant_reservations r where r.restaurant_id=p_restaurant_id and r.reservation_date=p_date and r.status not in ('cancelled','no_show','completed') and r.table_id=t.id and (r.reservation_time < p_time + make_interval(mins=>p_duration_minutes) and r.reservation_time + make_interval(mins=>coalesce(r.duration_minutes,90)) > p_time));
 return jsonb_build_object('available',available_tables>0,'table_count',available_tables);
end $$;

create or replace function public.anaira_assign_restaurant_table(p_reservation_id uuid,p_table_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.restaurant_reservations; t public.restaurant_reservation_tables;
begin
 select * into r from public.restaurant_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 select * into t from public.restaurant_reservation_tables where id=p_table_id and restaurant_id=r.restaurant_id and active=true for update;
 if not found or t.capacity<r.party_size then raise exception 'Table unavailable for party size'; end if;
 if exists(select 1 from public.restaurant_reservations x where x.restaurant_id=r.restaurant_id and x.table_id=t.id and x.id<>r.id and x.reservation_date=r.reservation_date and x.status not in ('cancelled','no_show','completed') and x.reservation_time < r.reservation_time + make_interval(mins=>coalesce(r.duration_minutes,90)) and x.reservation_time + make_interval(mins=>coalesce(x.duration_minutes,90)) > r.reservation_time) then raise exception 'Table is already reserved for this slot'; end if;
 update public.restaurant_reservations set table_id=t.id,status=case when status='pending' then 'confirmed' else status end,updated_at=now() where id=r.id;
 perform public.anaira_log_workflow_event(r.restaurant_id,'restaurant_reservation','reservation',r.id,'table_assigned',r.status,r.status,jsonb_build_object('table_id',t.id));
 return jsonb_build_object('reservation_id',r.id,'table_id',t.id,'status',r.status);
end $$;

create or replace function public.anaira_cancel_restaurant_reservation(p_reservation_id uuid,p_reason text default null)
returns jsonb language plpgsql security invoker as $$
declare r public.restaurant_reservations;
begin
 select * into r from public.restaurant_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 if r.status in ('cancelled','completed','no_show') then raise exception 'Reservation cannot be cancelled'; end if;
 update public.restaurant_reservations set status='cancelled',special_request=coalesce(special_request,'')||case when p_reason is null then '' else ' | Cancellation: '||p_reason end,updated_at=now() where id=r.id;
 perform public.anaira_log_workflow_event(r.restaurant_id,'restaurant_reservation','reservation',r.id,'cancelled',r.status,'cancelled',jsonb_build_object('reason',p_reason));
 return jsonb_build_object('reservation_id',r.id,'status','cancelled');
end $$;

create or replace function public.anaira_loyalty_earn(p_customer_id uuid,p_restaurant_id uuid,p_points integer,p_reference_type text default null,p_reference_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare a public.crm_loyalty_accounts;
begin
 if p_points<=0 then raise exception 'Points must be positive'; end if;
 select * into a from public.crm_loyalty_accounts where customer_id=p_customer_id and tenant_id=p_restaurant_id for update;
 if not found then insert into public.crm_loyalty_accounts(customer_id,tenant_id,tier,points_balance,lifetime_points) values(p_customer_id,p_restaurant_id,'Bronze',p_points,p_points) returning * into a;
 else update public.crm_loyalty_accounts set points_balance=points_balance+p_points,lifetime_points=lifetime_points+p_points where id=a.id returning * into a; end if;
 insert into public.crm_loyalty_transactions(loyalty_account_id,points,transaction_type,reference_type,reference_id,notes) values(a.id,p_points,'earn',p_reference_type,p_reference_id::text,'Earned through ANAIRA workflow');
 return jsonb_build_object('account_id',a.id,'balance',a.points_balance,'points',p_points);
end $$;

create or replace function public.anaira_loyalty_redeem(p_customer_id uuid,p_restaurant_id uuid,p_points integer,p_reference_type text default null,p_reference_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare a public.crm_loyalty_accounts;
begin
 if p_points<=0 then raise exception 'Points must be positive'; end if;
 select * into a from public.crm_loyalty_accounts where customer_id=p_customer_id and tenant_id=p_restaurant_id for update;
 if not found or a.points_balance<p_points then raise exception 'Insufficient loyalty balance'; end if;
 update public.crm_loyalty_accounts set points_balance=points_balance-p_points where id=a.id returning * into a;
 insert into public.crm_loyalty_transactions(loyalty_account_id,points,transaction_type,reference_type,reference_id,notes) values(a.id,-p_points,'redeem',p_reference_type,p_reference_id::text,'Redeemed through ANAIRA workflow');
 return jsonb_build_object('account_id',a.id,'balance',a.points_balance,'points_redeemed',p_points);
end $$;
