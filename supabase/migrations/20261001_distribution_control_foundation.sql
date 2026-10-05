-- ANAIRA DISTRIBUTION CONTROL FOUNDATION
-- Makes Room/Rate Mapping, Yield Management and Booking Source pages self-contained.
-- Existing production tables are preserved; CREATE IF NOT EXISTS is intentionally non-destructive.

create table if not exists public.ota_channels (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  provider text not null,
  status text not null default 'disconnected',
  credentials_ref text,
  last_sync_at timestamptz,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(restaurant_id,provider)
);

create table if not exists public.ota_room_mappings (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.ota_channels(id) on delete cascade,
  room_type_id uuid,
  external_code text not null,
  status text not null default 'mapped',
  metadata jsonb not null default '{}'::jsonb,
  unique(channel_id,external_code)
);

create table if not exists public.ota_rate_mappings (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.ota_channels(id) on delete cascade,
  rate_plan_id uuid,
  external_code text not null,
  status text not null default 'mapped',
  metadata jsonb not null default '{}'::jsonb,
  unique(channel_id,external_code)
);

create table if not exists public.ota_sync_events (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  channel_id uuid references public.ota_channels(id) on delete cascade,
  event_type text not null,
  status text not null default 'queued',
  payload jsonb not null default '{}'::jsonb,
  error_message text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create table if not exists public.hms_yield_rules (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  hospitality_type text not null default 'hotel',
  name text not null,
  room_type_id uuid,
  rate_plan_id uuid,
  trigger_type text not null default 'occupancy',
  min_value numeric,
  max_value numeric,
  adjustment_type text not null default 'percent',
  adjustment_value numeric not null default 0,
  min_rate numeric,
  max_rate numeric,
  min_los integer,
  max_los integer,
  booking_window_days integer,
  channel_scope jsonb not null default '[]'::jsonb,
  priority integer not null default 100,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hms_booking_sources (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  code text not null,
  category text not null default 'direct',
  channel_id uuid references public.ota_channels(id) on delete set null,
  default_rate_plan_id uuid,
  commission_percent numeric not null default 0,
  markup_percent numeric not null default 0,
  inventory_allocation_percent numeric,
  priority integer not null default 100,
  active boolean not null default true,
  booking_engine_enabled boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.ota_room_mappings enable row level security;
alter table public.ota_rate_mappings enable row level security;
alter table public.ota_sync_events enable row level security;
alter table public.hms_yield_rules enable row level security;
alter table public.hms_booking_sources enable row level security;

drop policy if exists ana_distribution_room_mapping_access on public.ota_room_mappings;
create policy ana_distribution_room_mapping_access on public.ota_room_mappings for all to authenticated using (exists(select 1 from public.ota_channels c where c.id=ota_room_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id))) with check (exists(select 1 from public.ota_channels c where c.id=ota_room_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)));

drop policy if exists ana_distribution_rate_mapping_access on public.ota_rate_mappings;
create policy ana_distribution_rate_mapping_access on public.ota_rate_mappings for all to authenticated using (exists(select 1 from public.ota_channels c where c.id=ota_rate_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id))) with check (exists(select 1 from public.ota_channels c where c.id=ota_rate_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)));

drop policy if exists ana_distribution_sync_access on public.ota_sync_events;
create policy ana_distribution_sync_access on public.ota_sync_events for all to authenticated using (public.anaira_tenant_access(restaurant_id)) with check (public.anaira_tenant_access(restaurant_id));

drop policy if exists ana_distribution_yield_access on public.hms_yield_rules;
create policy ana_distribution_yield_access on public.hms_yield_rules for all to authenticated using (public.anaira_tenant_access(restaurant_id)) with check (public.anaira_tenant_access(restaurant_id));

drop policy if exists ana_distribution_source_access on public.hms_booking_sources;
create policy ana_distribution_source_access on public.hms_booking_sources for all to authenticated using (public.anaira_tenant_access(restaurant_id)) with check (public.anaira_tenant_access(restaurant_id));

create unique index if not exists ota_room_mappings_channel_room_type_uidx on public.ota_room_mappings(channel_id,room_type_id) where room_type_id is not null;
create unique index if not exists ota_rate_mappings_channel_rate_plan_uidx on public.ota_rate_mappings(channel_id,rate_plan_id) where rate_plan_id is not null;
create index if not exists ota_sync_events_restaurant_created_idx on public.ota_sync_events(restaurant_id,created_at desc);
create index if not exists hms_yield_rules_scope_idx on public.hms_yield_rules(restaurant_id,hospitality_type,active,priority);
create index if not exists hms_booking_sources_scope_idx on public.hms_booking_sources(restaurant_id,active,priority);
