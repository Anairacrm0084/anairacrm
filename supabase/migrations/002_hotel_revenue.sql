create table if not exists public.crm_room_types (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  code text,
  base_rate numeric(12,2) not null default 0,
  min_rate numeric(12,2) not null default 0,
  max_rate numeric(12,2) not null default 0,
  max_occupancy integer not null default 2,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (min_rate >= 0),
  check (max_rate >= min_rate),
  check (base_rate >= min_rate and base_rate <= max_rate)
);

create table if not exists public.crm_rate_plans (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  room_type_id uuid not null references public.crm_room_types(id) on delete cascade,
  name text not null,
  code text,
  cancellation_policy text,
  meal_plan text,
  adjustment_percent numeric(7,3) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_pricing_rules (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  rule_type text not null,
  priority integer not null default 100,
  min_occupancy_pct numeric(5,2),
  max_occupancy_pct numeric(5,2),
  min_days_before integer,
  max_days_before integer,
  multiplier numeric(8,4) not null default 1,
  min_rate numeric(12,2),
  max_rate numeric(12,2),
  active boolean not null default true,
  valid_from date,
  valid_to date,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_revenue_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  event_date date not null,
  event_type text,
  multiplier numeric(8,4) not null default 1,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_daily_room_metrics (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  room_type_id uuid references public.crm_room_types(id) on delete cascade,
  metric_date date not null,
  total_rooms integer not null default 0,
  rooms_sold integer not null default 0,
  occupancy_pct numeric(6,2) not null default 0,
  bookings_on_books integer not null default 0,
  cancellations integer not null default 0,
  adr numeric(12,2),
  revpar numeric(12,2),
  created_at timestamptz not null default now(),
  unique(room_type_id, metric_date)
);

create table if not exists public.crm_rate_quotes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  room_type_id uuid references public.crm_room_types(id) on delete set null,
  quote_date date not null,
  base_rate numeric(12,2) not null,
  recommended_rate numeric(12,2) not null,
  minimum_rate numeric(12,2) not null,
  maximum_rate numeric(12,2) not null,
  multiplier numeric(8,4) not null,
  rule_breakdown jsonb not null default '[]'::jsonb,
  source text not null default 'engine',
  approved boolean not null default false,
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_revenue_metrics_date on public.crm_daily_room_metrics(metric_date);
create index if not exists idx_rate_quotes_date on public.crm_rate_quotes(quote_date);
create index if not exists idx_pricing_rules_active on public.crm_pricing_rules(active);

alter table public.crm_room_types enable row level security;
alter table public.crm_rate_plans enable row level security;
alter table public.crm_pricing_rules enable row level security;
alter table public.crm_revenue_events enable row level security;
alter table public.crm_daily_room_metrics enable row level security;
alter table public.crm_rate_quotes enable row level security;

create policy "room_types_authenticated" on public.crm_room_types for all to authenticated using (true) with check (true);
create policy "rate_plans_authenticated" on public.crm_rate_plans for all to authenticated using (true) with check (true);
create policy "pricing_rules_authenticated" on public.crm_pricing_rules for all to authenticated using (true) with check (true);
create policy "revenue_events_authenticated" on public.crm_revenue_events for all to authenticated using (true) with check (true);
create policy "daily_metrics_authenticated" on public.crm_daily_room_metrics for all to authenticated using (true) with check (true);
create policy "rate_quotes_authenticated" on public.crm_rate_quotes for all to authenticated using (true) with check (true);
