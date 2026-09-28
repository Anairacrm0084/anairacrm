-- P6: Integration Hub + cross-product E2E control plane
create extension if not exists pgcrypto;

alter table public.anaira_restaurant_connections
  add column if not exists connection_version bigint not null default 1,
  add column if not exists last_event_at timestamptz,
  add column if not exists last_event_status text,
  add column if not exists revoked_at timestamptz;

create table if not exists public.anaira_integration_event_contracts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.restaurants(id) on delete cascade,
  connection_id uuid references public.anaira_restaurant_connections(id) on delete cascade,
  event_id text not null,
  event_type text not null,
  payload_version text not null default '1.0',
  idempotency_key text not null,
  source text not null,
  destination text not null,
  entity_id text,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'received' check(status in ('received','processing','processed','failed','dead_letter')),
  attempts integer not null default 0,
  next_retry_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  unique(tenant_id,event_id),
  unique(tenant_id,idempotency_key)
);
create index if not exists anaira_p6_events_due on public.anaira_integration_event_contracts(status,next_retry_at,created_at);

create table if not exists public.anaira_integration_health_checks (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.restaurants(id) on delete cascade,
  connection_id uuid references public.anaira_restaurant_connections(id) on delete cascade,
  status text not null check(status in ('healthy','degraded','failed')),
  latency_ms integer,
  checked_at timestamptz not null default now(),
  error text,
  metadata jsonb not null default '{}'::jsonb
);
create index if not exists anaira_p6_health_idx on public.anaira_integration_health_checks(tenant_id,checked_at desc);

alter table public.anaira_integration_event_contracts enable row level security;
alter table public.anaira_integration_health_checks enable row level security;
drop policy if exists anaira_p6_events_access on public.anaira_integration_event_contracts;
create policy anaira_p6_events_access on public.anaira_integration_event_contracts for all to authenticated using(public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id)) with check(public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id));
drop policy if exists anaira_p6_health_access on public.anaira_integration_health_checks;
create policy anaira_p6_health_access on public.anaira_integration_health_checks for all to authenticated using(public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id)) with check(public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id));
