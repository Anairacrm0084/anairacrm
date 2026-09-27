-- Anaira Phase 14: replace demo-looking runtime surfaces with real operational primitives.
create extension if not exists pgcrypto;

create table if not exists public.crm_runtime_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, event_type text not null,
  source_system text not null, source_id uuid, status text not null default 'queued',
  payload jsonb not null default '{}'::jsonb, error text, created_at timestamptz not null default now(), processed_at timestamptz
);
create table if not exists public.crm_notification_queue (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, channel text not null,
  recipient text not null, template text, payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued', attempts int not null default 0, provider_message_id text,
  last_error text, scheduled_at timestamptz not null default now(), sent_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.crm_campaign_deliveries (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, campaign_id uuid not null,
  customer_id uuid, channel text not null, destination text, status text not null default 'queued',
  provider_message_id text, error text, sent_at timestamptz, delivered_at timestamptz, converted_at timestamptz,
  attributed_revenue numeric not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.crm_ota_sync_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, provider text not null,
  direction text not null, event_type text not null, external_id text, payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued', attempts int not null default 0, error text,
  created_at timestamptz not null default now(), processed_at timestamptz
);
create table if not exists public.crm_kitchen_tickets (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, order_id uuid,
  station text, status text not null default 'queued', priority int not null default 0,
  received_at timestamptz not null default now(), started_at timestamptz, ready_at timestamptz, bumped_at timestamptz
);
create table if not exists public.crm_bills (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, source_type text not null,
  source_id uuid, customer_id uuid, subtotal numeric not null default 0, tax numeric not null default 0,
  discount numeric not null default 0, total numeric not null default 0, paid numeric not null default 0,
  balance numeric not null default 0, status text not null default 'open', created_at timestamptz not null default now(), closed_at timestamptz
);
create table if not exists public.crm_bill_payments (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, bill_id uuid not null references public.crm_bills(id) on delete cascade,
  provider text, method text not null, amount numeric not null, reference text, status text not null default 'pending',
  created_at timestamptz not null default now(), settled_at timestamptz
);
create table if not exists public.crm_ai_runs (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, insight_type text not null,
  provider text, model text, input jsonb not null default '{}'::jsonb, output jsonb,
  status text not null default 'queued', error text, cost numeric, started_at timestamptz, completed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.crm_forecast_runs (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, model_version text not null,
  horizon_days int not null, status text not null default 'queued', metrics jsonb not null default '{}'::jsonb,
  error text, started_at timestamptz, completed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.crm_integration_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, provider text not null,
  event_type text not null, direction text not null, status text not null default 'queued',
  external_id text, payload jsonb not null default '{}'::jsonb, error text, attempts int not null default 0,
  created_at timestamptz not null default now(), processed_at timestamptz
);
create table if not exists public.crm_release_evidence (
  id uuid primary key default gen_random_uuid(), tenant_id uuid, check_name text not null,
  status text not null, evidence jsonb not null default '{}'::jsonb, checked_at timestamptz not null default now()
);

create index if not exists idx_runtime_events_tenant_status on public.crm_runtime_events(tenant_id,status,created_at desc);
create index if not exists idx_notification_queue_due on public.crm_notification_queue(status,scheduled_at);
create index if not exists idx_campaign_delivery_campaign on public.crm_campaign_deliveries(tenant_id,campaign_id,status);
create index if not exists idx_ota_events_queue on public.crm_ota_sync_events(tenant_id,status,created_at);
create index if not exists idx_kitchen_queue on public.crm_kitchen_tickets(tenant_id,status,priority desc,received_at);
create index if not exists idx_bill_tenant_status on public.crm_bills(tenant_id,status,created_at desc);
create index if not exists idx_ai_runs_tenant_status on public.crm_ai_runs(tenant_id,status,created_at desc);
create index if not exists idx_forecast_runs_tenant_status on public.crm_forecast_runs(tenant_id,status,created_at desc);
create index if not exists idx_integration_events_queue on public.crm_integration_events(tenant_id,status,created_at);

alter table public.crm_runtime_events enable row level security;
alter table public.crm_notification_queue enable row level security;
alter table public.crm_campaign_deliveries enable row level security;
alter table public.crm_ota_sync_events enable row level security;
alter table public.crm_kitchen_tickets enable row level security;
alter table public.crm_bills enable row level security;
alter table public.crm_bill_payments enable row level security;
alter table public.crm_ai_runs enable row level security;
alter table public.crm_forecast_runs enable row level security;
alter table public.crm_integration_events enable row level security;
alter table public.crm_release_evidence enable row level security;

create or replace function public.anaira_runtime_dashboard(p_tenant_id uuid)
returns jsonb language sql stable security invoker set search_path=public,pg_temp as $$
select jsonb_build_object(
 'crm_customers', (select count(*) from crm_customers where tenant_id=p_tenant_id),
 'active_workflows', (select count(*) from crm_workflows where tenant_id=p_tenant_id and active),
 'workflow_runs_today', (select count(*) from crm_workflow_runs where tenant_id=p_tenant_id and started_at >= current_date),
 'workflow_failures_today', (select count(*) from crm_workflow_runs where tenant_id=p_tenant_id and started_at >= current_date and status='failed'),
 'campaigns_active', (select count(*) from crm_campaigns where tenant_id=p_tenant_id and status in ('active','running','scheduled')),
 'campaign_deliveries_today', (select count(*) from crm_campaign_deliveries where tenant_id=p_tenant_id and created_at >= current_date),
 'notification_queue', (select count(*) from crm_notification_queue where tenant_id=p_tenant_id and status='queued'),
 'ota_pending', (select count(*) from crm_ota_sync_events where tenant_id=p_tenant_id and status='queued'),
 'kitchen_open', (select count(*) from crm_kitchen_tickets where tenant_id=p_tenant_id and status in ('queued','preparing','ready')),
 'open_bills', (select count(*) from crm_bills where tenant_id=p_tenant_id and status='open'),
 'ai_runs_today', (select count(*) from crm_ai_runs where tenant_id=p_tenant_id and created_at >= current_date),
 'forecast_runs', (select count(*) from crm_forecast_runs where tenant_id=p_tenant_id),
 'integration_events_today', (select count(*) from crm_integration_events where tenant_id=p_tenant_id and created_at >= current_date)
); $$;

create or replace function public.anaira_queue_notification(p_tenant_id uuid,p_channel text,p_recipient text,p_template text,p_payload jsonb,p_scheduled_at timestamptz default now())
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare v_id uuid;
begin
 insert into crm_notification_queue(tenant_id,channel,recipient,template,payload,scheduled_at)
 values(p_tenant_id,p_channel,p_recipient,p_template,coalesce(p_payload,'{}'),coalesce(p_scheduled_at,now())) returning id into v_id;
 return v_id;
end $$;

create or replace function public.anaira_record_runtime_event(p_tenant_id uuid,p_event_type text,p_source_system text,p_source_id uuid,p_payload jsonb)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare v_id uuid;
begin
 insert into crm_runtime_events(tenant_id,event_type,source_system,source_id,payload) values(p_tenant_id,p_event_type,p_source_system,p_source_id,coalesce(p_payload,'{}')) returning id into v_id;
 return v_id;
end $$;

create or replace function public.anaira_release_check(p_tenant_id uuid,p_check_name text,p_status text,p_evidence jsonb)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare v_id uuid;
begin
 insert into crm_release_evidence(tenant_id,check_name,status,evidence) values(p_tenant_id,p_check_name,p_status,coalesce(p_evidence,'{}')) returning id into v_id;
 return v_id;
end $$;
