create table if not exists public.crm_integration_connections (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  provider text not null,
  connection_name text not null,
  status text default 'disconnected',
  external_account_id text,
  config jsonb default '{}'::jsonb,
  last_sync_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.crm_integration_event_inbox (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  provider text not null,
  event_type text not null,
  external_event_id text,
  payload jsonb not null default '{}'::jsonb,
  status text default 'received',
  processed_at timestamptz,
  error text,
  created_at timestamptz default now(),
  unique(provider,external_event_id)
);

create table if not exists public.crm_sync_runs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  connection_id uuid references public.crm_integration_connections(id) on delete cascade,
  direction text not null,
  entity_type text not null,
  status text default 'running',
  records_read integer default 0,
  records_written integer default 0,
  error_count integer default 0,
  started_at timestamptz default now(),
  completed_at timestamptz
);

alter table public.crm_integration_connections enable row level security;
alter table public.crm_integration_event_inbox enable row level security;
alter table public.crm_sync_runs enable row level security;
create policy "integration_connections_auth" on public.crm_integration_connections for all to authenticated using (true) with check (true);
create policy "integration_event_inbox_auth" on public.crm_integration_event_inbox for all to authenticated using (true) with check (true);
create policy "sync_runs_auth" on public.crm_sync_runs for all to authenticated using (true) with check (true);
