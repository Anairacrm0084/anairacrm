-- OTA inbound reservation inbox. This is a durable, tenant-scoped import boundary;
-- it deliberately does not auto-confirm a PMS reservation until room/rate mappings
-- and provider payload semantics have been verified for the connected OTA account.
create table if not exists public.anaira_ota_reservation_inbox (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  connection_id uuid references public.anaira_distribution_connections(id) on delete set null,
  provider_code text not null,
  external_reference text not null,
  event_type text not null default 'reservation',
  reservation_status text not null default 'pending',
  guest_name text not null,
  guest_email text,
  guest_phone text,
  check_in date not null,
  check_out date not null,
  adults integer not null default 1,
  children integer not null default 0,
  amount numeric(12,2) not null default 0,
  currency text not null default 'INR',
  external_room_code text,
  external_rate_code text,
  room_type_id uuid references public.hms_room_types(id) on delete set null,
  rate_plan_id uuid references public.hms_rate_plans(id) on delete set null,
  import_status text not null default 'needs_mapping',
  hms_reservation_id uuid references public.hms_reservations(id) on delete set null,
  raw_payload jsonb not null default '{}'::jsonb,
  last_error text,
  received_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(restaurant_id, provider_code, external_reference),
  constraint ana_ota_inbox_dates_check check (check_out > check_in),
  constraint ana_ota_inbox_guests_check check (adults >= 1 and children >= 0),
  constraint ana_ota_inbox_amount_check check (amount >= 0),
  constraint ana_ota_inbox_status_check check (import_status in ('needs_mapping','ready','imported','cancelled','error','review'))
);
create index if not exists ana_ota_inbox_tenant_received_idx
  on public.anaira_ota_reservation_inbox(restaurant_id, received_at desc);
create index if not exists ana_ota_inbox_status_idx
  on public.anaira_ota_reservation_inbox(restaurant_id, import_status, received_at desc);
alter table public.anaira_ota_reservation_inbox enable row level security;
drop policy if exists ana_ota_inbox_tenant_access on public.anaira_ota_reservation_inbox;
create policy ana_ota_inbox_tenant_access on public.anaira_ota_reservation_inbox
  for all to authenticated
  using (public.anaira_current_is_super_admin() or public.anaira_tenant_access(restaurant_id))
  with check (public.anaira_current_is_super_admin() or public.anaira_tenant_access(restaurant_id));

alter table public.ota_sync_events add column if not exists direction text not null default 'outbound';
alter table public.ota_sync_events drop constraint if exists ota_sync_events_direction_check;
alter table public.ota_sync_events add constraint ota_sync_events_direction_check check (direction in ('inbound','outbound'));
