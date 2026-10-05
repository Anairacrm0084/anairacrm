-- Anaira AI Review: multi-business / multi-location expansion.
-- Keeps existing hospitality data intact and makes review context business-agnostic.

alter table public.crm_reviews add column if not exists business_vertical text not null default 'other';
alter table public.crm_reviews add column if not exists business_name text;
alter table public.crm_reviews add column if not exists service_context text;
alter table public.crm_review_sources add column if not exists business_vertical text not null default 'other';
alter table public.crm_review_sources add column if not exists business_name text;
alter table public.crm_review_request_jobs add column if not exists business_vertical text not null default 'other';
alter table public.crm_review_request_jobs add column if not exists customer_context jsonb not null default '{}'::jsonb;

create table if not exists public.crm_review_business_profiles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  business_vertical text not null default 'other',
  display_name text,
  category text,
  subcategory text,
  description text,
  service_labels jsonb not null default '[]'::jsonb,
  review_request_label text not null default 'Customer Review Request',
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id)
);

alter table public.crm_review_business_profiles enable row level security;
drop policy if exists tenant_access on public.crm_review_business_profiles;
create policy tenant_access on public.crm_review_business_profiles
for all to authenticated
using (public.anaira_tenant_access(tenant_id))
with check (public.anaira_tenant_access(tenant_id));

create index if not exists crm_reviews_business_vertical_idx on public.crm_reviews(tenant_id,business_vertical,reviewed_at desc);
create index if not exists crm_review_sources_business_vertical_idx on public.crm_review_sources(tenant_id,business_vertical);
create index if not exists crm_review_jobs_business_vertical_idx on public.crm_review_request_jobs(tenant_id,business_vertical,due_at);

-- Generic completed-interaction queue. Any vertical (barber, salon, clinic, shop,
-- professional service, etc.) can enqueue a customer interaction here without
-- changing the AI Review engine.
create table if not exists public.crm_review_request_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid not null,
  reference_type text not null default 'customer_interaction',
  reference_id text not null,
  business_vertical text not null default 'other',
  completed_at timestamptz not null default now(),
  delay_hours numeric not null default 24,
  status text not null default 'eligible',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);
alter table public.crm_review_request_events enable row level security;
drop policy if exists tenant_access on public.crm_review_request_events;
create policy tenant_access on public.crm_review_request_events
for all to authenticated using (public.anaira_tenant_access(tenant_id)) with check (public.anaira_tenant_access(tenant_id));
create index if not exists crm_review_request_events_queue_idx on public.crm_review_request_events(status,completed_at);
create index if not exists crm_review_request_events_tenant_idx on public.crm_review_request_events(tenant_id,business_vertical,completed_at desc);

-- Backfill legacy hospitality tenants without changing their canonical property model.
update public.crm_review_sources src
set business_vertical = case
  when lower(coalesce(r.business_type,'')) like '%restaurant%' and lower(coalesce(r.business_type,'')) not like '%hotel%' then 'restaurant'
  when lower(coalesce(r.business_type,'')) like '%hotel%' then 'hotel'
  else 'other'
end
from public.restaurants r
where src.tenant_id = r.id and coalesce(src.business_vertical,'other')='other';

update public.crm_reviews rv
set business_vertical = src.business_vertical,
    business_name = coalesce(rv.business_name,src.business_name,src.settings->>'title')
from public.crm_review_sources src
where rv.tenant_id=src.tenant_id and rv.source='google' and rv.business_vertical='other';
