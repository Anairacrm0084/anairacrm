-- Runtime RPC completion: every RPC called by the production UI has a concrete implementation.
create table if not exists public.anaira_pos_sync_queue (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 delivery_order_id uuid references public.delivery_orders(id) on delete set null,
 event_type text not null,
 status text not null default 'queued',
 payload jsonb not null default '{}'::jsonb,
 pos_order_id uuid,
 error_message text,
 created_at timestamptz not null default now(),
 processed_at timestamptz
);
create index if not exists anaira_pos_sync_queue_claim_idx on public.anaira_pos_sync_queue(restaurant_id,status,created_at);
alter table public.anaira_pos_sync_queue enable row level security;
drop policy if exists anaira_pos_sync_queue_tenant on public.anaira_pos_sync_queue;
create policy anaira_pos_sync_queue_tenant on public.anaira_pos_sync_queue for all to authenticated using(public.anaira_tenant_access(restaurant_id)) with check(public.anaira_tenant_access(restaurant_id));

create or replace function public.anaira_phase2_create_payment_intent(p_restaurant_id uuid,p_reference_type text,p_reference_id uuid,p_amount numeric,p_provider text default 'manual',p_idempotency_key text default null)
returns public.anaira_payment_intents language plpgsql security definer set search_path=public,pg_temp as $$
declare x public.anaira_payment_intents;
begin
 if auth.uid() is null and current_user<>'service_role' then raise exception 'Authentication required'; end if;
 if not(public.anaira_current_is_super_admin() or p_restaurant_id=public.anaira_current_restaurant_id()) and current_user<>'service_role' then raise exception 'Tenant access denied'; end if;
 if p_amount<=0 then raise exception 'Payment amount must be positive'; end if;
 if p_idempotency_key is not null then select * into x from public.anaira_payment_intents where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key for update; if found then return x; end if; end if;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,idempotency_key,status) values(p_restaurant_id,p_reference_type,p_reference_id,coalesce(p_provider,'manual'),p_amount,p_idempotency_key,'created') returning * into x;
 return x;
end $$;

create or replace function public.anaira_phase3_ack_pos_event(p_queue_id uuid,p_status text,p_pos_order_id uuid default null,p_error text default null)
returns public.anaira_pos_sync_queue language plpgsql security definer set search_path=public,pg_temp as $$
declare q public.anaira_pos_sync_queue;
begin
 select * into q from public.anaira_pos_sync_queue where id=p_queue_id for update;
 if not found then raise exception 'POS queue event not found'; end if;
 if not(public.anaira_current_is_super_admin() or q.restaurant_id=public.anaira_current_restaurant_id()) then raise exception 'Tenant access denied'; end if;
 update public.anaira_pos_sync_queue set status=coalesce(p_status,'processed'),pos_order_id=coalesce(p_pos_order_id,pos_order_id),error_message=p_error,processed_at=case when coalesce(p_status,'processed') in ('processed','failed','dead_letter') then now() else processed_at end where id=q.id returning * into q;
 return q;
end $$;

create or replace function public.anaira_phase4_claim_pos_queue(p_restaurant_id uuid,p_limit integer default 25)
returns setof public.anaira_pos_sync_queue language sql security definer set search_path=public,pg_temp as $$
with picked as (select id from public.anaira_pos_sync_queue where restaurant_id=p_restaurant_id and status='queued' order by created_at,id for update skip locked limit greatest(1,least(coalesce(p_limit,25),100)))
update public.anaira_pos_sync_queue q set status='processing' from picked where q.id=picked.id returning q.*;
$$;

create or replace function public.anaira_room_housekeeping_transition(p_restaurant_id uuid,p_room_id uuid,p_action text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare st text;
begin
 if not(public.anaira_current_is_super_admin() or p_restaurant_id=public.anaira_current_restaurant_id()) then raise exception 'Tenant access denied'; end if;
 st:=case p_action when 'start' then 'in_progress' when 'complete' then 'clean' when 'inspect' then 'inspected' when 'reopen' then 'dirty' when 'dirty' then 'dirty' when 'clean' then 'clean' else null end;
 if st is null then raise exception 'Invalid housekeeping action'; end if;
 return public.anaira_update_housekeeping(p_room_id,st,null);
end $$;

create or replace function public.anaira_set_inventory_controls(p_restaurant_id uuid,p_room_type_id uuid,p_stay_date date,p_stop_sell boolean default false,p_close_on_arrival boolean default false,p_close_on_departure boolean default false,p_cutoff_hours integer default null)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare i public.hms_inventory;
begin
 if not(public.anaira_current_is_super_admin() or p_restaurant_id=public.anaira_current_restaurant_id()) then raise exception 'Tenant access denied'; end if;
 select * into i from public.hms_inventory where restaurant_id=p_restaurant_id and room_type_id=p_room_type_id and stay_date=p_stay_date for update;
 if not found then raise exception 'Inventory row not found for selected date'; end if;
 update public.hms_inventory set stop_sell=coalesce(p_stop_sell,false),close_on_arrival=coalesce(p_close_on_arrival,false),close_on_departure=coalesce(p_close_on_departure,false),cutoff_hours=p_cutoff_hours where id=i.id returning * into i;
 return jsonb_build_object('ok',true,'inventory_id',i.id,'stop_sell',i.stop_sell,'close_on_arrival',i.close_on_arrival,'close_on_departure',i.close_on_departure,'cutoff_hours',i.cutoff_hours);
end $$;

create or replace function public.anaira_seed_booking_sources(p_restaurant_id uuid)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare n integer;
begin
 if not(public.anaira_current_is_super_admin() or p_restaurant_id=public.anaira_current_restaurant_id()) then raise exception 'Tenant access denied'; end if;
 insert into public.hms_booking_sources(restaurant_id,name,code,category,priority,active,booking_engine_enabled) values
 (p_restaurant_id,'Direct Website','DIRECT','direct',10,true,true),
 (p_restaurant_id,'Anaira Marketplace','ANAIRA','marketplace',20,true,true),
 (p_restaurant_id,'Walk-in','WALKIN','direct',30,true,false),
 (p_restaurant_id,'Phone','PHONE','direct',40,true,false),
 (p_restaurant_id,'OTA','OTA','ota',50,true,true)
 on conflict(restaurant_id,code) do update set name=excluded.name,category=excluded.category,active=true,updated_at=now();
 get diagnostics n=row_count; return n;
end $$;

create or replace function public.anaira_verify_hotel_payment(p_reservation_id uuid,p_submission_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.hms_reservations%rowtype; s public.anaira_hotel_payment_submissions%rowtype; pi public.anaira_payment_intents%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into r from public.hms_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 if not(public.anaira_current_is_super_admin() or r.restaurant_id=public.anaira_current_restaurant_id()) then raise exception 'Tenant access denied'; end if;
 select * into s from public.anaira_hotel_payment_submissions where id=p_submission_id and reservation_id=p_reservation_id for update;
 if not found then raise exception 'Payment submission not found'; end if;
 if s.status='verified' then return jsonb_build_object('ok',true,'already_verified',true,'reservation_id',r.id); end if;
 update public.anaira_hotel_payment_submissions set status='verified',updated_at=now() where id=s.id;
 if s.payment_intent_id is not null then update public.anaira_payment_intents set status='paid',updated_at=now() where id=s.payment_intent_id returning * into pi; end if;
 update public.hms_reservations set paid_amount=greatest(coalesce(paid_amount,0),coalesce(total_amount,0)),balance_amount=0,payment_status='paid',payment_method=coalesce(s.method,payment_method),payment_reference=coalesce(s.note,payment_reference),updated_at=now() where id=r.id;
 return jsonb_build_object('ok',true,'reservation_id',r.id,'payment_submission_id',s.id,'status','paid','paid_amount',coalesce(r.total_amount,0));
end $$;
