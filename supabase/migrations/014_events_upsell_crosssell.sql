create table if not exists public.crm_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  event_type text not null,
  name text not null,
  venue text,
  event_date date,
  expected_guests integer,
  stage text default 'lead',
  estimated_value numeric(14,2) default 0,
  owner_id uuid,
  notes text,
  created_at timestamptz default now()
);

create table if not exists public.crm_event_quotes (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.crm_events(id) on delete cascade,
  quote_id uuid references public.crm_quotes(id) on delete set null,
  package_definition jsonb default '{}'::jsonb
);

create table if not exists public.crm_upsell_offers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  offer_type text not null,
  product_reference text,
  price numeric(14,2) default 0,
  eligibility jsonb default '{}'::jsonb,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.crm_upsell_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  offer_id uuid references public.crm_upsell_offers(id) on delete set null,
  reference_type text,
  reference_id text,
  status text default 'offered',
  created_at timestamptz default now()
);

create table if not exists public.crm_cross_sell_rules (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  source_context text not null,
  target_product text not null,
  eligibility jsonb default '{}'::jsonb,
  active boolean default true
);

alter table public.crm_events enable row level security;
alter table public.crm_event_quotes enable row level security;
alter table public.crm_upsell_offers enable row level security;
alter table public.crm_upsell_events enable row level security;
alter table public.crm_cross_sell_rules enable row level security;
create policy "events_auth" on public.crm_events for all to authenticated using (true) with check (true);
create policy "event_quotes_auth" on public.crm_event_quotes for all to authenticated using (true) with check (true);
create policy "upsell_offers_auth" on public.crm_upsell_offers for all to authenticated using (true) with check (true);
create policy "upsell_events_auth" on public.crm_upsell_events for all to authenticated using (true) with check (true);
create policy "cross_sell_rules_auth" on public.crm_cross_sell_rules for all to authenticated using (true) with check (true);
