create table if not exists public.crm_guest_stays (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  external_booking_id text,
  property_id uuid,
  room_type_id uuid references public.crm_room_types(id) on delete set null,
  room_number text,
  check_in_date date,
  check_out_date date,
  nights integer default 0,
  booking_source text,
  booking_status text default 'confirmed',
  total_amount numeric(14,2) default 0,
  cancellation_reason text,
  no_show boolean default false,
  special_requests text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crm_guest_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  stay_id uuid references public.crm_guest_stays(id) on delete set null,
  request_type text not null,
  description text,
  priority text default 'normal',
  status text default 'open',
  assigned_to uuid,
  requested_at timestamptz default now(),
  completed_at timestamptz
);

create table if not exists public.crm_guest_upsells (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  stay_id uuid references public.crm_guest_stays(id) on delete set null,
  offer_type text not null,
  offer_name text not null,
  amount numeric(14,2),
  status text default 'offered',
  offered_at timestamptz default now(),
  accepted_at timestamptz
);

alter table public.crm_guest_stays enable row level security;
alter table public.crm_guest_requests enable row level security;
alter table public.crm_guest_upsells enable row level security;
create policy "guest_stays_auth" on public.crm_guest_stays for all to authenticated using (true) with check (true);
create policy "guest_requests_auth" on public.crm_guest_requests for all to authenticated using (true) with check (true);
create policy "guest_upsells_auth" on public.crm_guest_upsells for all to authenticated using (true) with check (true);
