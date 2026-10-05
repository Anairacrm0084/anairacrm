-- ANAIRA HOTEL GUEST CRM ENTERPRISE COMPLETION
-- Multi-property identity, event ingestion, segment/cross-sell rule engines,
-- immutable loyalty adjustments, AI action registry, provider webhooks and scheduler metadata.
-- Idempotent migration: safe to apply more than once.

create table if not exists public.anaira_hospitality_properties_master (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  source_table text not null,
  source_id uuid not null,
  property_type text not null default 'hotel',
  name text not null,
  destination text,
  city text,
  state text,
  country text,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(source_table,source_id)
);
alter table public.anaira_hospitality_properties_master enable row level security;
drop policy if exists ana_hospitality_property_access on public.anaira_hospitality_properties_master;
create policy ana_hospitality_property_access on public.anaira_hospitality_properties_master for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

insert into public.anaira_hospitality_properties_master(tenant_id,source_table,source_id,property_type,name,destination,city,state,country,active,metadata)
select p.restaurant_id,'anaira_stay_properties',p.id,coalesce(nullif(p.stay_type,''),'hotel'),p.name,p.destination,p.city,p.state,p.country,coalesce(p.active,true),jsonb_build_object('source','anaira_stay_properties')
from public.anaira_stay_properties p
on conflict(source_table,source_id) do update set name=excluded.name,property_type=excluded.property_type,destination=excluded.destination,city=excluded.city,state=excluded.state,country=excluded.country,active=excluded.active,updated_at=now();
insert into public.anaira_hospitality_properties_master(tenant_id,source_table,source_id,property_type,name,active,metadata)
select p.business_id,'anaira_hotel_properties',p.id,'hotel',p.name,coalesce(p.active,true),jsonb_build_object('source','anaira_hotel_properties')
from public.anaira_hotel_properties p
on conflict(source_table,source_id) do update set name=excluded.name,property_type=excluded.property_type,active=excluded.active,updated_at=now();
insert into public.anaira_hospitality_properties_master(tenant_id,source_table,source_id,property_type,name,destination,city,state,country,active,metadata)
select p.restaurant_id,'camp_properties',p.id,'camp',p.name,p.destination,p.city,p.state,p.country,coalesce(p.active,true),jsonb_build_object('source','camp_properties')
from public.camp_properties p
on conflict(source_table,source_id) do update set name=excluded.name,property_type=excluded.property_type,destination=excluded.destination,city=excluded.city,state=excluded.state,country=excluded.country,active=excluded.active,updated_at=now();

alter table public.crm_guest_stays add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
create index if not exists crm_guest_stays_property_idx on public.crm_guest_stays(tenant_id,property_id,check_in_date desc);
create table if not exists public.crm_customer_property_links (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  property_id uuid not null references public.anaira_hospitality_properties_master(id) on delete cascade,
  relationship_type text not null default 'guest',
  first_seen_at timestamptz not null default now(), last_seen_at timestamptz not null default now(), metadata jsonb not null default '{}'::jsonb,
  unique(customer_id,property_id,relationship_type)
);
alter table public.crm_customer_property_links enable row level security;
drop policy if exists crm_customer_property_links_access on public.crm_customer_property_links;
create policy crm_customer_property_links_access on public.crm_customer_property_links for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_source_event_inbox (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null,
  source_system text not null, event_type text not null, external_event_id text not null, payload jsonb not null default '{}'::jsonb,
  status text not null default 'received', attempts integer not null default 0, last_error text, received_at timestamptz not null default now(), processed_at timestamptz,
  unique(source_system,external_event_id)
);
create index if not exists crm_source_event_inbox_status_idx on public.crm_source_event_inbox(tenant_id,status,received_at);
alter table public.crm_source_event_inbox enable row level security;
drop policy if exists crm_source_event_inbox_access on public.crm_source_event_inbox;
create policy crm_source_event_inbox_access on public.crm_source_event_inbox for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_source_event_delivery_log (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, inbox_event_id uuid references public.crm_source_event_inbox(id) on delete cascade,
  source_system text not null, event_type text not null, attempt integer not null default 1, status text not null, response jsonb not null default '{}'::jsonb,
  error text, created_at timestamptz not null default now()
);
alter table public.crm_source_event_delivery_log enable row level security;
drop policy if exists crm_source_event_delivery_log_access on public.crm_source_event_delivery_log;
create policy crm_source_event_delivery_log_access on public.crm_source_event_delivery_log for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_segment_rules (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, segment_id uuid not null references public.crm_segments(id) on delete cascade,
  rule_group integer not null default 0, field_name text not null, operator text not null, value_json jsonb not null default 'null'::jsonb,
  conjunction text not null default 'AND', position integer not null default 0, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(segment_id,position)
);
alter table public.crm_segment_rules enable row level security;
drop policy if exists crm_segment_rules_access on public.crm_segment_rules;
create policy crm_segment_rules_access on public.crm_segment_rules for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

alter table public.crm_cross_sell_rules add column if not exists name text;
alter table public.crm_cross_sell_rules add column if not exists min_stay_nights integer;
alter table public.crm_cross_sell_rules add column if not exists guest_type text;
alter table public.crm_cross_sell_rules add column if not exists min_revenue numeric(14,2);
alter table public.crm_cross_sell_rules add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_cross_sell_rules add column if not exists active_from timestamptz;
alter table public.crm_cross_sell_rules add column if not exists active_until timestamptz;
alter table public.crm_cross_sell_rules add column if not exists priority integer not null default 100;

alter table public.crm_loyalty_transactions add column if not exists reversed_transaction_id uuid references public.crm_loyalty_transactions(id) on delete set null;
alter table public.crm_loyalty_transactions add column if not exists expires_at timestamptz;
alter table public.crm_loyalty_transactions add column if not exists reversed_at timestamptz;
create index if not exists crm_loyalty_transactions_expiry_idx on public.crm_loyalty_transactions(expires_at) where expires_at is not null;
create or replace function public.anaira_reverse_loyalty_transaction(p_transaction_id uuid,p_reason text default null)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare t public.crm_loyalty_transactions; a public.crm_loyalty_accounts; r uuid; begin
 select * into t from public.crm_loyalty_transactions where id=p_transaction_id for update;
 if t.id is null then raise exception 'LOYALTY_TRANSACTION_NOT_FOUND'; end if;
 if t.reversed_at is not null then raise exception 'LOYALTY_TRANSACTION_ALREADY_REVERSED'; end if;
 select * into a from public.crm_loyalty_accounts where id=t.loyalty_account_id for update;
 insert into public.crm_loyalty_transactions(loyalty_account_id,points,transaction_type,reference_type,reference_id,notes)
 values(a.id,-t.points,'reversal','loyalty_transaction',t.id::text,coalesce(p_reason,'Reversal')) returning id into r;
 update public.crm_loyalty_transactions set reversed_at=now(),reversed_transaction_id=r where id=t.id;
 update public.crm_loyalty_accounts set points_balance=points_balance-t.points,updated_at=now() where id=a.id;
 return jsonb_build_object('original_transaction_id',t.id,'reversal_transaction_id',r,'status','reversed');
end $$;
revoke all on function public.anaira_reverse_loyalty_transaction(uuid,text) from public;
grant execute on function public.anaira_reverse_loyalty_transaction(uuid,text) to authenticated;

create table if not exists public.crm_ai_action_registry (
  id uuid primary key default gen_random_uuid(), tenant_id uuid, action_type text not null, name text not null, description text, executor text not null,
  requires_approval boolean not null default true, enabled boolean not null default true, config jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), unique(tenant_id,action_type)
);
alter table public.crm_ai_action_registry enable row level security;
drop policy if exists crm_ai_action_registry_access on public.crm_ai_action_registry;
create policy crm_ai_action_registry_access on public.crm_ai_action_registry for all to authenticated
using (tenant_id is null or public.anaira_can_access_tenant(tenant_id)) with check (tenant_id is null or public.anaira_can_access_tenant(tenant_id));
insert into public.crm_ai_action_registry(tenant_id,action_type,name,executor,requires_approval) values
(null,'create_task','Create Task','crm',true),(null,'create_upsell','Create Upsell','crm',true),(null,'create_cross_sell','Create Cross-sell','crm',true),(null,'set_vip','Set VIP','crm',true),(null,'send_whatsapp','Send WhatsApp','provider',true),(null,'send_email','Send Email','provider',true),(null,'create_recovery','Create Recovery','crm',true),(null,'create_retention_task','Create Retention Task','crm',true)
on conflict(tenant_id,action_type) do nothing;

create table if not exists public.crm_provider_configs (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, provider text not null, channel text not null, sender_identity text, enabled boolean not null default false,
  config jsonb not null default '{}'::jsonb, secret_ref text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(tenant_id,provider,channel)
);
alter table public.crm_provider_configs enable row level security;
drop policy if exists crm_provider_configs_access on public.crm_provider_configs;
create policy crm_provider_configs_access on public.crm_provider_configs for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_provider_webhook_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, provider text not null, external_event_id text not null, event_type text not null,
  payload jsonb not null default '{}'::jsonb, status text not null default 'received', processed_at timestamptz, error text, created_at timestamptz not null default now(), unique(provider,external_event_id)
);
alter table public.crm_provider_webhook_events enable row level security;
drop policy if exists crm_provider_webhook_events_access on public.crm_provider_webhook_events;
create policy crm_provider_webhook_events_access on public.crm_provider_webhook_events for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_automation_schedules (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, name text not null, worker text not null, cadence text not null default 'hourly', enabled boolean not null default true,
  next_run_at timestamptz, last_run_at timestamptz, last_status text, config jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(tenant_id,name)
);
alter table public.crm_automation_schedules enable row level security;
drop policy if exists crm_automation_schedules_access on public.crm_automation_schedules;
create policy crm_automation_schedules_access on public.crm_automation_schedules for all to authenticated
using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

-- Backfill property links from existing CRM stays when a property can be resolved by tenant.
insert into public.crm_customer_property_links(tenant_id,customer_id,property_id,relationship_type,last_seen_at)
select s.tenant_id,s.customer_id,s.property_id,'guest',coalesce(s.updated_at,now())
from public.crm_guest_stays s where s.customer_id is not null and s.property_id is not null
on conflict(customer_id,property_id,relationship_type) do update set last_seen_at=excluded.last_seen_at;

-- Safe defaults for scheduler metadata. Actual invocation remains the application's scheduler/cron responsibility.
insert into public.crm_automation_schedules(tenant_id,name,worker,cadence,enabled,next_run_at)
select r.id,'hotel_guest_crm_functional','/api/crm/functional-worker','hourly',true,now()
from public.restaurants r
on conflict(tenant_id,name) do nothing;
