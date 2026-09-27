create table if not exists public.crm_customer_channels (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  channel text not null,
  address text,
  verified boolean default false,
  preferred boolean default false,
  active boolean default true,
  unique(customer_id,channel,address)
);

create table if not exists public.crm_relationship_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  staff_id uuid not null,
  assignment_type text default 'relationship_manager',
  active boolean default true,
  assigned_at timestamptz default now(),
  unassigned_at timestamptz
);

create table if not exists public.crm_data_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  request_type text not null,
  status text default 'received',
  requested_at timestamptz default now(),
  completed_at timestamptz
);

alter table public.crm_customer_channels enable row level security;
alter table public.crm_relationship_assignments enable row level security;
alter table public.crm_data_requests enable row level security;
create policy "customer_channels_auth" on public.crm_customer_channels for all to authenticated using (true) with check (true);
create policy "relationship_assignments_auth" on public.crm_relationship_assignments for all to authenticated using (true) with check (true);
create policy "data_requests_auth" on public.crm_data_requests for all to authenticated using (true) with check (true);
