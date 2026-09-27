create table if not exists public.crm_review_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  channel text not null,
  requested_at timestamptz default now(),
  status text default 'pending',
  review_url text
);

create table if not exists public.crm_service_recovery (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  complaint_id uuid references public.crm_complaints(id) on delete cascade,
  customer_id uuid references public.crm_customers(id) on delete set null,
  recovery_type text,
  value numeric(14,2) default 0,
  approved_by uuid,
  status text default 'proposed',
  created_at timestamptz default now()
);

create table if not exists public.crm_sla_rules (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  complaint_type text not null,
  priority text not null,
  first_response_minutes integer,
  resolution_minutes integer,
  active boolean default true
);

alter table public.crm_review_requests enable row level security;
alter table public.crm_service_recovery enable row level security;
alter table public.crm_sla_rules enable row level security;
create policy "review_requests_auth" on public.crm_review_requests for all to authenticated using (true) with check (true);
create policy "service_recovery_auth" on public.crm_service_recovery for all to authenticated using (true) with check (true);
create policy "sla_rules_auth" on public.crm_sla_rules for all to authenticated using (true) with check (true);
