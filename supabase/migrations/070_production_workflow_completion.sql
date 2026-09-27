-- ANAIRA 070: production workflow hardening
-- Requires migrations 066, 068 and 069. No provider secrets are stored here.

-- Strong idempotency and operational indexes.
alter table public.anaira_payment_events add column if not exists signature_verified boolean not null default false;

create unique index if not exists anaira_payment_events_provider_event_uidx on public.anaira_payment_events(provider,event_id) where event_id is not null;
create index if not exists anaira_workflow_events_created_idx on public.anaira_workflow_events(restaurant_id,created_at desc);
create index if not exists anaira_notification_queue_claim_idx on public.anaira_notification_queue(status,next_attempt_at,scheduled_at);
create index if not exists anaira_ota_queue_claim_idx on public.anaira_ota_sync_queue(status,next_attempt_at,created_at);

-- Generic, auditable state transition primitive for operational entities.
create or replace function public.anaira_log_transition(
  p_restaurant_id uuid,p_module text,p_entity_type text,p_entity_id uuid,
  p_event_type text,p_from_status text,p_to_status text,p_payload jsonb default '{}'
) returns uuid language plpgsql security invoker as $$
declare v_id uuid;
begin
  insert into public.anaira_workflow_events(restaurant_id,module,entity_type,entity_id,event_type,from_status,to_status,actor_id,payload)
  values(p_restaurant_id,p_module,p_entity_type,p_entity_id,p_event_type,p_from_status,p_to_status,auth.uid(),coalesce(p_payload,'{}'))
  returning id into v_id;
  return v_id;
end $$;

-- PMS: explicit room lifecycle with tenant lock and housekeeping coupling.
create or replace function public.anaira_pms_set_room_state(p_room_id uuid,p_status text,p_housekeeping_status text default null)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_rooms; old_status text;
begin
  select * into r from public.pms_rooms where id=p_room_id for update;
  if not found then raise exception 'Room not found'; end if;
  if p_status not in ('available','occupied','blocked','maintenance','out_of_order') then raise exception 'Invalid room status'; end if;
  if p_housekeeping_status is not null and p_housekeeping_status not in ('clean','dirty','inspected','out_of_order','in_progress') then raise exception 'Invalid housekeeping status'; end if;
  old_status:=r.status;
  update public.pms_rooms set status=p_status,housekeeping_status=coalesce(p_housekeeping_status,housekeeping_status),updated_at=now() where id=p_room_id;
  perform public.anaira_log_transition(r.restaurant_id,'pms','room',r.id,'room_state',old_status,p_status,jsonb_build_object('housekeeping_status',coalesce(p_housekeeping_status,r.housekeeping_status)));
  return jsonb_build_object('room_id',r.id,'status',p_status,'housekeeping_status',coalesce(p_housekeeping_status,r.housekeeping_status));
end $$;

-- PMS: checkout cannot complete with an unpaid folio when a folio exists.
create or replace function public.anaira_pms_safe_check_out(p_reservation_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.pms_reservations; f public.hms_folios;
begin
  select * into r from public.pms_reservations where id=p_reservation_id for update;
  if not found then raise exception 'Reservation not found'; end if;
  if r.status <> 'checked_in' then raise exception 'Reservation must be checked in'; end if;
  select * into f from public.hms_folios where reservation_id=p_reservation_id order by created_at desc limit 1 for update;
  if found and coalesce(f.balance,0)>0.005 then raise exception 'Folio has outstanding balance: %',f.balance; end if;
  return public.anaira_pms_check_out(p_reservation_id);
end $$;

-- Restaurant reservation: atomic table assignment with overlap prevention.
create or replace function public.anaira_reserve_table(p_reservation_id uuid,p_table_id uuid)
returns jsonb language plpgsql security invoker as $$
declare r public.restaurant_reservations; t public.restaurant_reservation_tables; conflict_id uuid;
begin
  select * into r from public.restaurant_reservations where id=p_reservation_id for update;
  if not found then raise exception 'Reservation not found'; end if;
  select * into t from public.restaurant_reservation_tables where id=p_table_id and restaurant_id=r.restaurant_id and active for update;
  if not found then raise exception 'Table not found'; end if;
  if t.capacity<r.party_size then raise exception 'Table capacity is insufficient'; end if;
  select id into conflict_id from public.restaurant_reservations x
  where x.restaurant_id=r.restaurant_id and x.table_id=t.id and x.reservation_date=r.reservation_date
    and x.id<>r.id and x.status not in ('cancelled','no_show','completed')
    and (r.reservation_time < x.reservation_time + make_interval(mins=>x.duration_minutes)
         and r.reservation_time + make_interval(mins=>r.duration_minutes) > x.reservation_time)
  limit 1 for update;
  if conflict_id is not null then raise exception 'Table is already reserved for this time slot'; end if;
  update public.restaurant_reservations set table_id=t.id,status=case when status in ('pending','requested','confirmed') then 'confirmed' else status end,updated_at=now() where id=r.id;
  perform public.anaira_log_transition(r.restaurant_id,'restaurant_reservation','reservation',r.id,'table_assigned',r.status,'confirmed',jsonb_build_object('table_id',t.id));
  return jsonb_build_object('reservation_id',r.id,'table_id',t.id,'status','confirmed');
end $$;

-- Delivery: one guarded state machine and optional rider assignment.
create or replace function public.anaira_delivery_transition_safe(p_order_id uuid,p_next_status text,p_rider_id uuid default null)
returns jsonb language plpgsql security invoker as $$
declare o public.delivery_orders; allowed boolean:=false;
begin
  select * into o from public.delivery_orders where id=p_order_id for update;
  if not found then raise exception 'Delivery order not found'; end if;
  if p_next_status not in ('placed','accepted','preparing','ready','rider_assigned','picked_up','out_for_delivery','delivered','cancelled','rejected','failed_delivery') then raise exception 'Invalid delivery status'; end if;
  allowed := (o.status,p_next_status) in (
    ('placed','accepted'),('placed','cancelled'),('placed','rejected'),
    ('accepted','preparing'),('accepted','cancelled'),('preparing','ready'),('preparing','cancelled'),
    ('ready','rider_assigned'),('ready','cancelled'),('rider_assigned','picked_up'),
    ('picked_up','out_for_delivery'),('out_for_delivery','delivered'),('out_for_delivery','failed_delivery'),
    ('failed_delivery','out_for_delivery'),('failed_delivery','cancelled')
  );
  if not allowed then raise exception 'Invalid delivery transition: % -> %',o.status,p_next_status; end if;
  if p_next_status='rider_assigned' and p_rider_id is null then raise exception 'Rider is required'; end if;
  if p_rider_id is not null then
    if not exists(select 1 from public.delivery_riders where id=p_rider_id and restaurant_id=o.restaurant_id and active) then raise exception 'Rider not available'; end if;
    update public.delivery_orders set rider_id=p_rider_id where id=o.id;
  end if;
  update public.delivery_orders set status=p_next_status,
    accepted_at=case when p_next_status='accepted' then coalesce(accepted_at,now()) else accepted_at end,
    ready_at=case when p_next_status='ready' then coalesce(ready_at,now()) else ready_at end,
    picked_up_at=case when p_next_status='picked_up' then coalesce(picked_up_at,now()) else picked_up_at end,
    delivered_at=case when p_next_status='delivered' then coalesce(delivered_at,now()) else delivered_at end
  where id=o.id;
  perform public.anaira_log_transition(o.restaurant_id,'delivery','order',o.id,'status_transition',o.status,p_next_status,jsonb_build_object('rider_id',p_rider_id));
  return jsonb_build_object('order_id',o.id,'from_status',o.status,'status',p_next_status,'rider_id',coalesce(p_rider_id,o.rider_id));
end $$;

-- Payment: server/webhook path only can mark paid; duplicate event is idempotent.
create or replace function public.anaira_mark_payment_verified(p_payment_intent_id uuid,p_status text,p_provider_payment_id text default null,p_event_id text default null,p_provider text default null,p_payload jsonb default '{}')
returns jsonb language plpgsql security invoker as $$
declare p public.anaira_payment_intents; old text; ev uuid;
begin
  if p_status not in ('authorized','paid','failed','cancelled','partially_refunded','refunded') then raise exception 'Invalid payment status'; end if;
  select * into p from public.anaira_payment_intents where id=p_payment_intent_id for update;
  if not found then raise exception 'Payment intent not found'; end if;
  old:=p.status;
  if p_event_id is not null and exists(select 1 from public.anaira_payment_events where provider=coalesce(p_provider,p.provider) and event_id=p_event_id) then
    return jsonb_build_object('idempotent',true,'payment_intent_id',p.id,'status',p.status);
  end if;
  update public.anaira_payment_intents set status=p_status,provider_payment_id=coalesce(p_provider_payment_id,provider_payment_id),updated_at=now() where id=p.id;
  insert into public.anaira_payment_events(payment_intent_id,provider,event_id,event_type,payload,signature_verified,processed_at)
  values(p.id,coalesce(p_provider,p.provider),p_event_id,'verified_status',coalesce(p_payload,'{}'),true,now()) on conflict(provider,event_id) do nothing returning id into ev;
  perform public.anaira_log_transition(p.restaurant_id,'payment','payment_intent',p.id,'payment_status',old,p_status,jsonb_build_object('provider',coalesce(p_provider,p.provider),'event_id',p_event_id));
  return jsonb_build_object('payment_intent_id',p.id,'status',p_status,'event_recorded',ev is not null);
end $$;

-- Notification queue retry/dead-letter semantics.
create or replace function public.anaira_retry_notification(p_id uuid,p_error text)
returns jsonb language plpgsql security invoker as $$
declare q public.anaira_notification_queue; next_status text; next_time timestamptz;
begin
 select * into q from public.anaira_notification_queue where id=p_id for update;
 if not found then raise exception 'Notification not found'; end if;
 next_status:=case when q.attempts>=5 then 'failed' else 'pending' end;
 next_time:=now()+make_interval(mins=>least(60,greatest(1,power(2,greatest(q.attempts-1,0))::int)));
 update public.anaira_notification_queue set status=case when next_status='failed' then 'failed' else 'queued' end,last_error=p_error,next_attempt_at=next_time,updated_at=now() where id=q.id;
 return jsonb_build_object('id',q.id,'status',next_status,'next_attempt_at',next_time);
end $$;

-- Immutable-ish audit event helper: deny direct update/delete at application level via trigger.
create or replace function public.anaira_prevent_workflow_event_mutation() returns trigger language plpgsql as $$
begin raise exception 'Workflow events are immutable'; end $$;
drop trigger if exists anaira_workflow_events_immutable on public.anaira_workflow_events;
create trigger anaira_workflow_events_immutable before update or delete on public.anaira_workflow_events for each row execute function public.anaira_prevent_workflow_event_mutation();

-- Health snapshot RPC: reports actual DB/provider queue state, never fabricated percentages.
create or replace function public.anaira_system_health_snapshot(p_restaurant_id uuid)
returns jsonb language plpgsql security invoker as $$
declare plugin_count int; store_count int; pending_payments int; pending_notifications int; pending_ota int;
begin
 select count(*) into plugin_count from public.restaurant_plugins where restaurant_id=p_restaurant_id;
 select count(*) into store_count from public.anaira_platform_stores where restaurant_id=p_restaurant_id;
 select count(*) into pending_payments from public.anaira_payment_intents where restaurant_id=p_restaurant_id and status in ('created','pending','authorized');
 select count(*) into pending_notifications from public.anaira_notification_queue where restaurant_id=p_restaurant_id and status in ('pending','processing');
 select count(*) into pending_ota from public.anaira_ota_sync_queue where restaurant_id=p_restaurant_id and status in ('pending','processing','retry','queued');
 return jsonb_build_object('database','PASS','plugin_registry',plugin_count,'platform_stores',store_count,'pending_payments',pending_payments,'pending_notifications',pending_notifications,'pending_ota',pending_ota,'generated_at',now());
end $$;
