create table if not exists public.crm_customer_insights (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  insight_type text not null,
  insight_key text not null,
  insight_value text,
  confidence numeric(6,5),
  source text default 'derived',
  observed_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique(customer_id, insight_type, insight_key)
);

create table if not exists public.crm_customer_value_snapshots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  snapshot_date date not null,
  hotel_revenue numeric(14,2) default 0,
  restaurant_revenue numeric(14,2) default 0,
  event_revenue numeric(14,2) default 0,
  ancillary_revenue numeric(14,2) default 0,
  total_revenue numeric(14,2) default 0,
  visit_count integer default 0,
  stay_nights integer default 0,
  calculated_ltv numeric(14,2) default 0,
  unique(customer_id,snapshot_date)
);

alter table public.crm_customer_insights enable row level security;
alter table public.crm_customer_value_snapshots enable row level security;
create policy "crm_customer_insights_auth" on public.crm_customer_insights for all to authenticated using (true) with check (true);
create policy "crm_customer_value_auth" on public.crm_customer_value_snapshots for all to authenticated using (true) with check (true);
