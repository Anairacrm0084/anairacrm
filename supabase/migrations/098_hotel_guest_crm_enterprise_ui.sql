-- ANAIRA HOTEL GUEST CRM ENTERPRISE UI / WORKFLOW SUPPORT
-- Adds relationship-layer records only; Booking Engine/PMS remain operational masters.

create table if not exists public.crm_guest_precheckins (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  stay_id uuid references public.crm_guest_stays(id) on delete set null,
  status text not null default 'not_started',
  arrival_time text,
  address text,
  special_requests text,
  consent boolean not null default false,
  verified_at timestamptz,
  verified_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists crm_guest_precheckins_tenant_idx on public.crm_guest_precheckins(tenant_id,status,created_at desc);
create index if not exists crm_guest_precheckins_customer_idx on public.crm_guest_precheckins(customer_id,created_at desc);

create table if not exists public.crm_guest_documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  stay_id uuid references public.crm_guest_stays(id) on delete set null,
  document_type text not null,
  storage_path text,
  verification_status text not null default 'pending',
  verified_at timestamptz,
  verified_by uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists crm_guest_documents_tenant_idx on public.crm_guest_documents(tenant_id,verification_status,created_at desc);

create table if not exists public.crm_guest_stay_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid references public.crm_customers(id) on delete set null,
  stay_id uuid references public.crm_guest_stays(id) on delete set null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  source text not null default 'crm',
  created_at timestamptz not null default now()
);
create index if not exists crm_guest_stay_events_tenant_idx on public.crm_guest_stay_events(tenant_id,created_at desc);
create index if not exists crm_guest_stay_events_customer_idx on public.crm_guest_stay_events(customer_id,created_at desc);

alter table public.crm_guest_requests add column if not exists sla_due_at timestamptz;
alter table public.crm_guest_requests add column if not exists first_response_at timestamptz;
alter table public.crm_guest_requests add column if not exists escalated_at timestamptz;
alter table public.crm_guest_requests add column if not exists sla_status text default 'within_sla';
alter table public.crm_guest_requests add column if not exists category text;

alter table public.crm_complaints add column if not exists stay_id uuid references public.crm_guest_stays(id) on delete set null;
alter table public.crm_complaints add column if not exists root_cause text;
alter table public.crm_complaints add column if not exists compensation numeric(14,2) default 0;
alter table public.crm_complaints add column if not exists recovery_offer text;

alter table public.crm_guest_precheckins enable row level security;
alter table public.crm_guest_documents enable row level security;
alter table public.crm_guest_stay_events enable row level security;

drop policy if exists crm_guest_precheckins_tenant on public.crm_guest_precheckins;
create policy crm_guest_precheckins_tenant on public.crm_guest_precheckins for all to authenticated using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
drop policy if exists crm_guest_documents_tenant on public.crm_guest_documents;
create policy crm_guest_documents_tenant on public.crm_guest_documents for all to authenticated using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
drop policy if exists crm_guest_stay_events_tenant on public.crm_guest_stay_events;
create policy crm_guest_stay_events_tenant on public.crm_guest_stay_events for all to authenticated using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

comment on table public.crm_guest_precheckins is 'Hotel Guest CRM pre-check-in relationship record. PMS remains owner of actual check-in.';
comment on table public.crm_guest_documents is 'Metadata for securely stored guest verification documents; storage bucket/policy is managed separately.';
comment on table public.crm_guest_stay_events is 'Hotel guest lifecycle event timeline; operational state remains owned by PMS/Booking Engine.';
