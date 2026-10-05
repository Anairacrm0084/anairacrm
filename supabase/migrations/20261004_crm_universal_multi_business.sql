-- ANAIRA UNIVERSAL MULTI-BUSINESS CRM
-- Makes CRM vertical-agnostic while preserving existing hospitality/restaurant modules.
create table if not exists public.crm_business_profiles (
  tenant_id uuid primary key,
  business_vertical text not null default 'other',
  business_name text,
  website_platform text,
  enabled boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.crm_business_profiles enable row level security;
drop policy if exists crm_business_profiles_access on public.crm_business_profiles;
create policy crm_business_profiles_access on public.crm_business_profiles
for all to authenticated
using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));

create index if not exists crm_business_profiles_vertical_idx on public.crm_business_profiles(business_vertical);

create table if not exists public.crm_universal_interactions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid references public.crm_customers(id) on delete set null,
  business_vertical text not null default 'other',
  interaction_type text not null,
  source_system text not null default 'crm',
  source_id text,
  status text not null default 'completed',
  subject text,
  amount numeric(14,2),
  currency text default 'INR',
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.crm_universal_interactions enable row level security;
drop policy if exists crm_universal_interactions_access on public.crm_universal_interactions;
create policy crm_universal_interactions_access on public.crm_universal_interactions
for all to authenticated
using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));

create index if not exists crm_universal_interactions_tenant_time_idx on public.crm_universal_interactions(tenant_id,occurred_at desc);
create index if not exists crm_universal_interactions_customer_idx on public.crm_universal_interactions(customer_id,occurred_at desc);
create index if not exists crm_universal_interactions_vertical_idx on public.crm_universal_interactions(tenant_id,business_vertical,interaction_type);

create table if not exists public.crm_universal_service_profiles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  business_vertical text not null default 'other',
  service_code text not null,
  service_name text not null,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id,service_code)
);
alter table public.crm_universal_service_profiles enable row level security;
drop policy if exists crm_universal_service_profiles_access on public.crm_universal_service_profiles;
create policy crm_universal_service_profiles_access on public.crm_universal_service_profiles
for all to authenticated
using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_crm_record_universal_interaction(
  p_tenant_id uuid,p_customer_id uuid,p_business_vertical text,p_interaction_type text,
  p_subject text default null,p_amount numeric default null,p_currency text default 'INR',
  p_source_system text default 'crm',p_source_id text default null,p_metadata jsonb default '{}'::jsonb,
  p_occurred_at timestamptz default now()
) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid;
begin
  if not public.anaira_can_access_tenant(p_tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;
  insert into public.crm_universal_interactions(tenant_id,customer_id,business_vertical,interaction_type,subject,amount,currency,source_system,source_id,metadata,occurred_at)
  values(p_tenant_id,p_customer_id,coalesce(nullif(lower(p_business_vertical),''),'other'),lower(p_interaction_type),p_subject,p_amount,coalesce(p_currency,'INR'),coalesce(p_source_system,'crm'),p_source_id,coalesce(p_metadata,'{}'::jsonb),coalesce(p_occurred_at,now()))
  returning id into v_id;
  return v_id;
end $$;

grant execute on function public.anaira_crm_record_universal_interaction(uuid,uuid,text,text,text,numeric,text,text,text,jsonb,timestamptz) to authenticated;

-- Backfill existing tenants as hospitality-aware without changing existing records.
insert into public.crm_business_profiles(tenant_id,business_vertical,business_name,metadata)
select r.id,case when exists(select 1 from public.anaira_hospitality_properties_master p where p.tenant_id=r.id and p.property_type='hotel') then 'hotel' when exists(select 1 from public.anaira_hospitality_properties_master p where p.tenant_id=r.id and p.property_type='camp') then 'camp' else 'restaurant' end,r.name,jsonb_build_object('source','universal-crm-backfill')
from public.restaurants r
on conflict(tenant_id) do nothing;
