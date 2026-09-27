create table if not exists public.crm_corporate_contacts (
  id uuid primary key default gen_random_uuid(),
  corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
  customer_id uuid references public.crm_customers(id) on delete set null,
  role_title text,
  primary_contact boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.crm_corporate_contracts (
  id uuid primary key default gen_random_uuid(),
  corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
  contract_number text,
  start_date date,
  end_date date,
  negotiated_terms jsonb default '{}'::jsonb,
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists public.crm_partner_bookings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  partner_id uuid references public.crm_partners(id) on delete set null,
  customer_id uuid references public.crm_customers(id) on delete set null,
  booking_reference text,
  booking_amount numeric(14,2) default 0,
  commission_amount numeric(14,2) default 0,
  status text default 'confirmed',
  created_at timestamptz default now()
);

alter table public.crm_corporate_contacts enable row level security;
alter table public.crm_corporate_contracts enable row level security;
alter table public.crm_partner_bookings enable row level security;
create policy "corporate_contacts_auth" on public.crm_corporate_contacts for all to authenticated using (true) with check (true);
create policy "corporate_contracts_auth" on public.crm_corporate_contracts for all to authenticated using (true) with check (true);
create policy "partner_bookings_auth" on public.crm_partner_bookings for all to authenticated using (true) with check (true);
