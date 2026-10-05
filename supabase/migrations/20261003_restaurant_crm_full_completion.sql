
-- Restaurant CRM production completion: property scope, operational writes,
-- customer preferences, service/SLA, offers, marketing queue, timeline/audit.
begin;

alter table public.crm_customers add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_customer_preferences add column if not exists tenant_id uuid;
alter table public.crm_customer_preferences add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_food_preferences add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_tasks add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_complaints add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_feedback add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_consents add column if not exists tenant_id uuid;
alter table public.crm_consents add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_guest_requests add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_loyalty_accounts add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_loyalty_transactions add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_churn_scores add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_vip_profiles add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_segments add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_campaigns add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_campaign_recipients add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_message_log add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_coupon_definitions add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_coupon_redemptions add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_timeline_events add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_commercial_offers add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.restaurant_reservations add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;

-- Reservations can be safely backfilled only when the tenant has exactly one active property.
do $$
declare r record;
begin
 for r in
   select rr.restaurant_id, max(p.id) as property_id
   from public.restaurant_reservations rr
   join public.anaira_hospitality_properties_master p on p.tenant_id=rr.restaurant_id and p.active=true
   where rr.property_id is null
   group by rr.restaurant_id
   having count(p.id)=1
 loop
   update public.restaurant_reservations set property_id=r.property_id
   where restaurant_id=r.restaurant_id and property_id is null;
 end loop;
end $$;

-- Backfill only when the canonical customer already gives an unambiguous property.
update public.crm_customer_preferences p set tenant_id=c.tenant_id, property_id=coalesce(p.property_id,c.property_id)
from public.crm_customers c where c.id=p.customer_id and (p.tenant_id is null or p.property_id is null);
update public.crm_food_preferences p set property_id=c.property_id
from public.crm_customers c where c.id=p.customer_id and p.property_id is null and c.property_id is not null;
update public.crm_tasks t set property_id=c.property_id
from public.crm_customers c where c.id=t.customer_id and t.property_id is null and c.property_id is not null;
update public.crm_complaints x set property_id=c.property_id
from public.crm_customers c where c.id=x.customer_id and x.property_id is null and c.property_id is not null;
update public.crm_feedback x set property_id=c.property_id
from public.crm_customers c where c.id=x.customer_id and x.property_id is null and c.property_id is not null;
update public.crm_consents x set tenant_id=c.tenant_id, property_id=c.property_id
from public.crm_customers c where c.id=x.customer_id and (x.tenant_id is null or x.property_id is null);
update public.crm_guest_requests x set property_id=c.property_id
from public.crm_customers c where c.id=x.customer_id and x.property_id is null and c.property_id is not null;
update public.crm_loyalty_accounts x set property_id=c.property_id
from public.crm_customers c where c.id=x.customer_id and x.property_id is null and c.property_id is not null;
update public.crm_churn_scores x set property_id=c.property_id
from public.crm_customers c where c.id=x.customer_id and x.property_id is null and c.property_id is not null;
update public.crm_vip_profiles x set property_id=c.property_id
from public.crm_customers c where c.id=x.customer_id and x.property_id is null and c.property_id is not null;

create index if not exists restaurant_reservations_property_idx on public.restaurant_reservations(restaurant_id,property_id,reservation_date,reservation_time,status);

create index if not exists crm_customers_tenant_property_idx on public.crm_customers(tenant_id,property_id,updated_at desc);
create index if not exists crm_customer_preferences_property_idx on public.crm_customer_preferences(tenant_id,property_id,customer_id);
create index if not exists crm_food_preferences_property_idx on public.crm_food_preferences(tenant_id,property_id,customer_id);
create index if not exists crm_tasks_property_customer_idx on public.crm_tasks(tenant_id,property_id,customer_id,status);
create index if not exists crm_complaints_property_idx on public.crm_complaints(tenant_id,property_id,status,opened_at desc);
create index if not exists crm_feedback_property_idx on public.crm_feedback(tenant_id,property_id,customer_id,created_at desc);
create index if not exists crm_guest_requests_property_idx on public.crm_guest_requests(tenant_id,property_id,customer_id,status);
create index if not exists crm_loyalty_accounts_property_idx on public.crm_loyalty_accounts(tenant_id,property_id,customer_id);
create index if not exists crm_churn_property_idx on public.crm_churn_scores(tenant_id,property_id,customer_id);
create index if not exists crm_campaigns_property_idx on public.crm_campaigns(tenant_id,property_id,status);
create index if not exists crm_campaign_recipients_property_idx on public.crm_campaign_recipients(tenant_id,property_id,campaign_id,status);
create index if not exists crm_message_log_property_idx on public.crm_message_log(tenant_id,property_id,customer_id,created_at desc);
create index if not exists crm_timeline_property_customer_idx on public.crm_timeline_events(tenant_id,property_id,customer_id,occurred_at desc);
create index if not exists crm_commercial_offers_property_customer_idx on public.crm_commercial_offers(tenant_id,property_id,customer_id,status);

create table if not exists public.crm_restaurant_customer_actions (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 property_id uuid not null references public.anaira_hospitality_properties_master(id) on delete cascade,
 customer_id uuid references public.crm_customers(id) on delete set null,
 action_type text not null,
 status text not null default 'created',
 payload jsonb not null default '{}'::jsonb,
 result jsonb not null default '{}'::jsonb,
 created_by uuid,
 created_at timestamptz not null default now(),
 completed_at timestamptz
);
alter table public.crm_restaurant_customer_actions enable row level security;
drop policy if exists restaurant_customer_actions_tenant on public.crm_restaurant_customer_actions;
create policy restaurant_customer_actions_tenant on public.crm_restaurant_customer_actions
for all to authenticated
using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));
create index if not exists crm_restaurant_customer_actions_idx on public.crm_restaurant_customer_actions(tenant_id,property_id,customer_id,created_at desc);



-- Full restaurant commercial/automation closure: orders, campaign audience jobs,
-- automation queue and AI/provider audit metadata. These structures never fabricate
-- provider success; external delivery remains queued until a real provider responds.
alter table public.anaira_marketplace_orders add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.delivery_orders add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;

update public.anaira_marketplace_orders o
set property_id=p.id
from public.anaira_hospitality_properties_master p
where o.property_id is null and p.tenant_id=o.restaurant_id and p.active=true
  and (select count(*) from public.anaira_hospitality_properties_master p2 where p2.tenant_id=o.restaurant_id and p2.active=true)=1;
update public.delivery_orders o
set property_id=p.id
from public.anaira_hospitality_properties_master p
where o.property_id is null and p.tenant_id=o.restaurant_id
  and (select count(*) from public.anaira_hospitality_properties_master p2 where p2.tenant_id=o.restaurant_id and p2.active=true)=1;

create table if not exists public.crm_restaurant_order_events (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 property_id uuid not null references public.anaira_hospitality_properties_master(id) on delete cascade,
 customer_id uuid references public.crm_customers(id) on delete set null,
 order_id uuid not null,
 order_source text not null,
 event_type text not null,
 from_status text,
 to_status text,
 amount numeric,
 payment_status text,
 payload jsonb not null default '{}'::jsonb,
 idempotency_key text,
 created_by uuid,
 created_at timestamptz not null default now(),
 unique(tenant_id, idempotency_key)
);
alter table public.crm_restaurant_order_events enable row level security;
drop policy if exists crm_restaurant_order_events_tenant on public.crm_restaurant_order_events;
create policy crm_restaurant_order_events_tenant on public.crm_restaurant_order_events
for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));
create index if not exists crm_restaurant_order_events_idx on public.crm_restaurant_order_events(tenant_id,property_id,customer_id,created_at desc);

create table if not exists public.crm_restaurant_campaign_jobs (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 property_id uuid not null references public.anaira_hospitality_properties_master(id) on delete cascade,
 campaign_id uuid not null references public.crm_campaigns(id) on delete cascade,
 status text not null default 'queued',
 attempts integer not null default 0,
 run_at timestamptz not null default now(),
 last_error text,
 created_at timestamptz not null default now(),
 completed_at timestamptz
);
alter table public.crm_restaurant_campaign_jobs enable row level security;
drop policy if exists crm_restaurant_campaign_jobs_tenant on public.crm_restaurant_campaign_jobs;
create policy crm_restaurant_campaign_jobs_tenant on public.crm_restaurant_campaign_jobs
for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));
create index if not exists crm_restaurant_campaign_jobs_idx on public.crm_restaurant_campaign_jobs(status,run_at);

create table if not exists public.crm_restaurant_automation_jobs (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 property_id uuid not null references public.anaira_hospitality_properties_master(id) on delete cascade,
 customer_id uuid references public.crm_customers(id) on delete set null,
 trigger_type text not null,
 action_type text not null,
 payload jsonb not null default '{}'::jsonb,
 status text not null default 'queued',
 attempts integer not null default 0,
 max_attempts integer not null default 5,
 run_at timestamptz not null default now(),
 last_error text,
 created_at timestamptz not null default now(),
 completed_at timestamptz
);
alter table public.crm_restaurant_automation_jobs enable row level security;
drop policy if exists crm_restaurant_automation_jobs_tenant on public.crm_restaurant_automation_jobs;
create policy crm_restaurant_automation_jobs_tenant on public.crm_restaurant_automation_jobs
for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));
create index if not exists crm_restaurant_automation_jobs_idx on public.crm_restaurant_automation_jobs(status,run_at);

create or replace function public.anaira_restaurant_crm_action(
 p_tenant_id uuid,
 p_property_id uuid,
 p_action text,
 p_customer_id uuid default null,
 p_payload jsonb default '{}'::jsonb
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp
as $$
declare
 v_customer public.crm_customers%rowtype;
 v_id uuid;
 v_result jsonb := '{}'::jsonb;
 v_action public.crm_restaurant_customer_actions%rowtype;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 if not public.anaira_can_access_tenant(p_tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;
 if not exists(select 1 from public.anaira_hospitality_properties_master where id=p_property_id and tenant_id=p_tenant_id and active=true) then
   raise exception 'PROPERTY_ACCESS_DENIED';
 end if;
 if p_customer_id is not null then
   select * into v_customer from public.crm_customers where id=p_customer_id and tenant_id=p_tenant_id and property_id=p_property_id;
   if v_customer.id is null then raise exception 'CUSTOMER_ACCESS_DENIED'; end if;
 end if;

 if p_action='create_task' then
   insert into public.crm_tasks(tenant_id,property_id,customer_id,title,status,priority,due_at,assigned_to)
   values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'title','Restaurant CRM follow-up'),'open',coalesce(p_payload->>'priority','normal'),nullif(p_payload->>'due_at','')::timestamptz,nullif(p_payload->>'assigned_to','')::uuid)
   returning id into v_id;
   v_result:=jsonb_build_object('task_id',v_id);
 elsif p_action='create_complaint' then
   insert into public.crm_complaints(tenant_id,property_id,customer_id,title,description,priority,status)
   values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'title','Restaurant complaint'),p_payload->>'description',coalesce(p_payload->>'priority','normal'),'open')
   returning id into v_id;
   v_result:=jsonb_build_object('complaint_id',v_id);
 elsif p_action='resolve_complaint' then
   v_id:=nullif(p_payload->>'complaint_id','')::uuid;
   update public.crm_complaints set status='resolved',resolution=p_payload->>'resolution',resolved_at=now()
   where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
   if not found then raise exception 'COMPLAINT_NOT_FOUND'; end if;
   v_result:=jsonb_build_object('complaint_id',v_id,'status','resolved');
 elsif p_action='create_food_preference' then
   insert into public.crm_food_preferences(tenant_id,property_id,customer_id,preference_type,value,frequency,confidence,last_seen_at)
   values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'preference_type','diet'),coalesce(p_payload->>'value',''),coalesce((p_payload->>'frequency')::numeric,1),coalesce((p_payload->>'confidence')::numeric,1),now())
   on conflict(customer_id,preference_type,value) do update set frequency=excluded.frequency,confidence=excluded.confidence,last_seen_at=now();
   v_result:=jsonb_build_object('ok',true);
 elsif p_action='create_preference' then
   insert into public.crm_customer_preferences(tenant_id,property_id,customer_id,preference_key,preference_value,source,confidence)
   values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'key','preference'),p_payload->>'value',coalesce(p_payload->>'source','manual'),coalesce((p_payload->>'confidence')::numeric,1))
   on conflict(customer_id,preference_key) do update set preference_value=excluded.preference_value,source=excluded.source,confidence=excluded.confidence;
   v_result:=jsonb_build_object('ok',true);
 elsif p_action='create_request' then
   insert into public.crm_guest_requests(tenant_id,property_id,customer_id,request_type,description,priority,status)
   values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'request_type','restaurant_service'),p_payload->>'description',coalesce(p_payload->>'priority','normal'),'open')
   returning id into v_id;
   v_result:=jsonb_build_object('request_id',v_id);
 elsif p_action='complete_task' then
   v_id:=nullif(p_payload->>'task_id','')::uuid;
   update public.crm_tasks set status='completed' where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
   if not found then raise exception 'TASK_NOT_FOUND'; end if;
   v_result:=jsonb_build_object('task_id',v_id,'status','completed');
 elsif p_action='complete_request' then
   v_id:=nullif(p_payload->>'request_id','')::uuid;
   update public.crm_guest_requests set status='completed',completed_at=now() where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
   if not found then raise exception 'REQUEST_NOT_FOUND'; end if;
   v_result:=jsonb_build_object('request_id',v_id,'status','completed');
 elsif p_action='escalate_request' then
   v_id:=nullif(p_payload->>'request_id','')::uuid;
   update public.crm_guest_requests set status='escalated' where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
   if not found then raise exception 'REQUEST_NOT_FOUND'; end if;
   v_result:=jsonb_build_object('request_id',v_id,'status','escalated');
 elsif p_action='create_sla_event' then
   insert into public.crm_service_sla_events(tenant_id,property_id,ticket_id,event_type,due_at,actor_id,payload)
   values(p_tenant_id,p_property_id,nullif(p_payload->>'ticket_id','')::uuid,coalesce(p_payload->>'event_type','sla_created'),nullif(p_payload->>'due_at','')::timestamptz,auth.uid(),coalesce(p_payload,'{}'::jsonb))
   returning id into v_id;
   v_result:=jsonb_build_object('sla_event_id',v_id);
 elsif p_action='create_offer' then
   insert into public.crm_commercial_offers(tenant_id,property_id,customer_id,source_stay_id,offer_type,title,price,currency,inventory_ref,status,expires_at,metadata)
   values(p_tenant_id,p_property_id,p_customer_id,null,coalesce(p_payload->>'offer_type','restaurant_upsell'),coalesce(p_payload->>'title','Restaurant offer'),coalesce((p_payload->>'price')::numeric,0),coalesce(p_payload->>'currency','INR'),p_payload->>'inventory_ref','proposed',nullif(p_payload->>'expires_at','')::timestamptz,coalesce(p_payload->'metadata','{}'::jsonb))
   returning id into v_id;
   v_result:=jsonb_build_object('offer_id',v_id);
 elsif p_action='accept_offer' then
   v_id:=nullif(p_payload->>'offer_id','')::uuid;
   update public.crm_commercial_offers set status='accepted',accepted_at=now()
   where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and customer_id=p_customer_id and status='proposed' and (expires_at is null or expires_at>now());
   if not found then raise exception 'OFFER_NOT_AVAILABLE'; end if;
   v_result:=jsonb_build_object('offer_id',v_id,'status','accepted');
 elsif p_action='fulfil_offer' then
   v_id:=nullif(p_payload->>'offer_id','')::uuid;
   update public.crm_commercial_offers set status='fulfilled',fulfilled_at=now(),revenue=coalesce(revenue,price)
   where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and customer_id=p_customer_id and status in ('accepted','paid');
   if not found then raise exception 'OFFER_NOT_ACCEPTED'; end if;
   v_result:=jsonb_build_object('offer_id',v_id,'status','fulfilled');
 elsif p_action='log_feedback' then
   insert into public.crm_feedback(tenant_id,property_id,customer_id,overall_rating,food_rating,service_rating,comment,source)
   values(p_tenant_id,p_property_id,p_customer_id,(p_payload->>'rating')::numeric,(p_payload->>'rating')::numeric,(p_payload->>'rating')::numeric,p_payload->>'comment',coalesce(p_payload->>'source','restaurant_crm'))
   returning id into v_id;
   v_result:=jsonb_build_object('feedback_id',v_id);
 elsif p_action='queue_whatsapp' then
   insert into public.crm_message_log(tenant_id,property_id,customer_id,channel,direction,status,payload,created_at)
   values(p_tenant_id,p_property_id,p_customer_id,'whatsapp','outbound','queued',coalesce(p_payload,'{}'::jsonb),now())
   returning id into v_id;
   v_result:=jsonb_build_object('message_id',v_id,'status','queued','provider_required',true);
 elsif p_action='add_timeline' then
   v_id:=public.anaira_record_crm_timeline(p_tenant_id,p_customer_id,coalesce(p_payload->>'event_type','restaurant_crm'), 'restaurant_crm',coalesce(p_payload->>'source_id',gen_random_uuid()::text),coalesce(p_payload->>'title','Restaurant CRM event'),p_payload->>'description',null,coalesce(p_payload->'metadata','{}'::jsonb),now());
   v_result:=jsonb_build_object('timeline_id',v_id);
 elsif p_action='redeem_loyalty' then
   v_result:=public.anaira_loyalty_redeem(p_customer_id,(p_payload->>'points')::integer,'restaurant_crm',p_payload->>'reference_id');
 elsif p_action='earn_loyalty' then
   v_result:=public.anaira_loyalty_post(p_tenant_id,p_customer_id,'restaurant',coalesce((p_payload->>'amount')::numeric,0),'restaurant_crm',p_payload->>'reference_id');
 elsif p_action='pay_offer' then
   v_id:=nullif(p_payload->>'offer_id','')::uuid;
   update public.crm_commercial_offers set status='paid',paid_at=now(),revenue=coalesce(revenue,price)
   where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and customer_id=p_customer_id and status='accepted';
   if not found then raise exception 'OFFER_NOT_PAYABLE'; end if;
   v_result:=jsonb_build_object('offer_id',v_id,'status','paid');
 elsif p_action='record_order_event' then
   if lower(coalesce(p_payload->>'order_source','')) not in ('marketplace','delivery','bill') then raise exception 'INVALID_ORDER_SOURCE'; end if;
   insert into public.crm_restaurant_order_events(tenant_id,property_id,customer_id,order_id,order_source,event_type,from_status,to_status,amount,payment_status,payload,idempotency_key,created_by)
   values(p_tenant_id,p_property_id,p_customer_id,nullif(p_payload->>'order_id','')::uuid,lower(p_payload->>'order_source'),coalesce(p_payload->>'event_type','status_change'),p_payload->>'from_status',p_payload->>'to_status',(p_payload->>'amount')::numeric,p_payload->>'payment_status',coalesce(p_payload,'{}'::jsonb),p_payload->>'idempotency_key',auth.uid())
   on conflict(tenant_id,idempotency_key) do update set payload=excluded.payload
   returning id into v_id;
   if lower(p_payload->>'order_source')='marketplace' then
     update public.anaira_marketplace_orders set status=coalesce(p_payload->>'to_status',status),property_id=p_property_id,crm_customer_id=coalesce(crm_customer_id,p_customer_id)
     where id=(p_payload->>'order_id')::uuid and restaurant_id=p_tenant_id;
   elsif lower(p_payload->>'order_source')='delivery' then
     update public.delivery_orders set status=coalesce(p_payload->>'to_status',status),property_id=p_property_id,customer_id=coalesce(customer_id,p_customer_id)
     where id=(p_payload->>'order_id')::uuid and restaurant_id=p_tenant_id;
   elsif lower(p_payload->>'order_source')='bill' then
     update public.crm_bills set status=coalesce(p_payload->>'to_status',status),property_id=p_property_id,customer_id=coalesce(customer_id,p_customer_id)
     where id=(p_payload->>'order_id')::uuid and tenant_id=p_tenant_id;
   end if;
   v_result:=jsonb_build_object('order_event_id',v_id,'status',coalesce(p_payload->>'to_status','recorded'));
 elsif p_action='record_order_payment' then
   if lower(coalesce(p_payload->>'order_source',''))='bill' then
     insert into public.crm_bill_payments(tenant_id,bill_id,provider,method,amount,reference,status,settled_at)
     values(p_tenant_id,(p_payload->>'order_id')::uuid,p_payload->>'provider',coalesce(p_payload->>'method','unknown'),coalesce((p_payload->>'amount')::numeric,0),p_payload->>'reference',coalesce(p_payload->>'status','pending'),case when p_payload->>'status' in ('paid','captured','settled') then now() end)
     returning id into v_id;
   else
     insert into public.crm_restaurant_order_events(tenant_id,property_id,customer_id,order_id,order_source,event_type,amount,payment_status,payload,created_by)
     values(p_tenant_id,p_property_id,p_customer_id,(p_payload->>'order_id')::uuid,lower(p_payload->>'order_source'),'payment',coalesce((p_payload->>'amount')::numeric,0),p_payload->>'status',coalesce(p_payload,'{}'::jsonb),auth.uid()) returning id into v_id;
   end if;
   v_result:=jsonb_build_object('payment_event_id',v_id,'status',coalesce(p_payload->>'status','pending'));
 elsif p_action='prepare_campaign' then
   v_id:=nullif(p_payload->>'campaign_id','')::uuid;
   if not exists(select 1 from public.crm_campaigns where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id) then raise exception 'CAMPAIGN_NOT_FOUND'; end if;
   insert into public.crm_campaign_recipients(id,campaign_id,customer_id,status,tenant_id,property_id)
   select gen_random_uuid(),v_id,c.id,'queued',p_tenant_id,p_property_id
   from public.crm_customers c
   left join public.crm_restaurant_customer_metrics m on m.customer_id=c.id and m.tenant_id=p_tenant_id and m.property_id=p_property_id
   where c.tenant_id=p_tenant_id and c.property_id=p_property_id
     and (nullif(p_payload->>'min_visits','') is null or coalesce(m.total_visits,0) >= (p_payload->>'min_visits')::int)
   on conflict do nothing;
   update public.crm_campaigns set status='audience_ready' where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
   insert into public.crm_restaurant_campaign_jobs(tenant_id,property_id,campaign_id) values(p_tenant_id,p_property_id,v_id);
   v_result:=jsonb_build_object('campaign_id',v_id,'status','audience_ready');
 elsif p_action='queue_automation' then
   insert into public.crm_restaurant_automation_jobs(tenant_id,property_id,customer_id,trigger_type,action_type,payload,run_at)
   values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'trigger_type','manual'),coalesce(p_payload->>'action_type','add_timeline'),coalesce(p_payload,'{}'::jsonb),coalesce(nullif(p_payload->>'run_at','')::timestamptz,now())) returning id into v_id;
   v_result:=jsonb_build_object('job_id',v_id,'status','queued');
 elsif p_action='generate_ai_insight' then
   if nullif(trim(p_payload->>'summary'),'') is null then raise exception 'AI_OUTPUT_REQUIRED'; end if;
   insert into public.crm_ai_insights(tenant_id,property_id,customer_id,insight_type,summary,recommendation,confidence,model_name,model_version,input_snapshot)
   values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'insight_type','restaurant'),p_payload->>'summary',p_payload->>'recommendation',(p_payload->>'confidence')::numeric,p_payload->>'model_name',p_payload->>'model_version',coalesce(p_payload->'input_snapshot','{}'::jsonb)) returning id into v_id;
   v_result:=jsonb_build_object('insight_id',v_id,'status','generated','provider_response_recorded',true);
 else
   raise exception 'UNSUPPORTED_RESTAURANT_CRM_ACTION';
 end if;

 insert into public.crm_restaurant_customer_actions(tenant_id,property_id,customer_id,action_type,status,payload,result,created_by,completed_at)
 values(p_tenant_id,p_property_id,p_customer_id,p_action,'completed',coalesce(p_payload,'{}'::jsonb),coalesce(v_result,'{}'::jsonb),auth.uid(),now())
 returning * into v_action;

 if p_customer_id is not null then
   perform public.anaira_record_crm_timeline(p_tenant_id,p_customer_id,'restaurant_crm.'||p_action,'restaurant_crm',v_action.id::text,initcap(replace(p_action,'_',' ')),null,null,coalesce(v_result,'{}'::jsonb),now());
 end if;
 perform public.anaira_crm_record_action(p_tenant_id,p_property_id,'restaurant_crm',v_action.id,p_action,coalesce(v_result,'{}'::jsonb));
 return jsonb_build_object('ok',true,'action_id',v_action.id,'result',v_result);
exception when others then
 if p_tenant_id is not null and public.anaira_can_access_tenant(p_tenant_id) then
   insert into public.crm_restaurant_customer_actions(tenant_id,property_id,customer_id,action_type,status,payload,result,created_by)
   values(p_tenant_id,p_property_id,p_customer_id,p_action,'failed',coalesce(p_payload,'{}'::jsonb),jsonb_build_object('error',sqlerrm),auth.uid());
 end if;
 raise;
end $$;

revoke all on function public.anaira_restaurant_crm_action(uuid,uuid,text,uuid,jsonb) from public,anon;
grant execute on function public.anaira_restaurant_crm_action(uuid,uuid,text,uuid,jsonb) to authenticated;

commit;
