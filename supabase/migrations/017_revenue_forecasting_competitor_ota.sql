create table if not exists public.crm_revenue_forecasts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  property_id uuid,
  room_type_id uuid references public.crm_room_types(id) on delete set null,
  forecast_date date not null,
  horizon_days integer not null,
  occupancy_forecast numeric(6,2),
  adr_forecast numeric(12,2),
  revpar_forecast numeric(12,2),
  demand_index numeric(8,4),
  confidence numeric(6,5),
  model_version text,
  factors jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.crm_competitor_rates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  competitor_name text not null,
  room_type_label text,
  stay_date date not null,
  rate numeric(12,2),
  currency text default 'INR',
  source text,
  captured_at timestamptz default now()
);

create table if not exists public.crm_channel_performance (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  channel text not null,
  metric_date date not null,
  bookings integer default 0,
  room_nights integer default 0,
  revenue numeric(14,2) default 0,
  commission numeric(14,2) default 0,
  cancellations integer default 0,
  conversion_rate numeric(8,5),
  avg_rate numeric(12,2),
  unique(channel,metric_date)
);

create table if not exists public.crm_rate_parity_snapshots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  stay_date date not null,
  room_type_label text,
  direct_rate numeric(12,2),
  channel_rates jsonb default '{}'::jsonb,
  parity_status text,
  captured_at timestamptz default now()
);

alter table public.crm_revenue_forecasts enable row level security;
alter table public.crm_competitor_rates enable row level security;
alter table public.crm_channel_performance enable row level security;
alter table public.crm_rate_parity_snapshots enable row level security;
create policy "revenue_forecasts_auth" on public.crm_revenue_forecasts for all to authenticated using (true) with check (true);
create policy "competitor_rates_auth" on public.crm_competitor_rates for all to authenticated using (true) with check (true);
create policy "channel_performance_auth" on public.crm_channel_performance for all to authenticated using (true) with check (true);
create policy "rate_parity_auth" on public.crm_rate_parity_snapshots for all to authenticated using (true) with check (true);
