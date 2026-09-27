-- Phase 31: Master A-to-Z completion hardening
-- Adds durable control-plane state for verification, deployment, alerts, provider telemetry and certification.
create extension if not exists pgcrypto;

alter table public.crm_seo_sites
  add column if not exists verification_methods jsonb not null default '["dns_txt","html_file","meta_tag"]'::jsonb,
  add column if not exists verification_last_checked_at timestamptz,
  add column if not exists verification_failure_reason text,
  add column if not exists canonical_host text,
  add column if not exists deployment_policy jsonb not null default '{}'::jsonb;

create table if not exists public.crm_seo_verification_history(
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  method text not null,
  status text not null,
  evidence jsonb not null default '{}'::jsonb,
  error_message text,
  checked_at timestamptz not null default now(),
  actor_id uuid
);
create index if not exists crm_seo_verification_history_idx on public.crm_seo_verification_history(site_id,checked_at desc);

create table if not exists public.crm_seo_deployment_runs(
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  target_type text not null,
  action text not null,
  status text not null default 'pending',
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,
  error_message text,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  actor_id uuid
);
create index if not exists crm_seo_deployment_runs_idx on public.crm_seo_deployment_runs(site_id,started_at desc);

create table if not exists public.crm_seo_alert_rules(
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  alert_type text not null,
  enabled boolean not null default true,
  threshold jsonb not null default '{}'::jsonb,
  channels jsonb not null default '["in_app"]'::jsonb,
  recipients jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(site_id,alert_type)
);

create table if not exists public.crm_seo_alert_events(
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  alert_type text not null,
  severity text not null default 'warning',
  title text not null,
  message text not null,
  payload jsonb not null default '{}'::jsonb,
  delivery_status jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists crm_seo_alert_events_idx on public.crm_seo_alert_events(site_id,created_at desc);

create table if not exists public.crm_seo_provider_calls(
  id uuid primary key default gen_random_uuid(),
  site_id uuid references public.crm_seo_sites(id) on delete cascade,
  provider text not null,
  operation text not null,
  status text not null,
  latency_ms integer,
  status_code integer,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists crm_seo_provider_calls_idx on public.crm_seo_provider_calls(site_id,provider,created_at desc);

create table if not exists public.crm_seo_certification_runs(
  id uuid primary key default gen_random_uuid(),
  site_id uuid references public.crm_seo_sites(id) on delete cascade,
  checklist_version text not null,
  status text not null,
  results jsonb not null default '{}'::jsonb,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists crm_seo_certification_runs_idx on public.crm_seo_certification_runs(site_id,started_at desc);

do $$ declare t text; begin
  foreach t in array array['crm_seo_verification_history','crm_seo_deployment_runs','crm_seo_alert_rules','crm_seo_alert_events','crm_seo_provider_calls','crm_seo_certification_runs'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('drop policy if exists tenant_access on public.%I',t);
    if t='crm_seo_provider_calls' then
      execute format('create policy tenant_access on public.%I for all to authenticated using (site_id is null or exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (site_id is null or exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)))',t);
    else
      execute format('create policy tenant_access on public.%I for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)))',t);
    end if;
  end loop;
end $$;
