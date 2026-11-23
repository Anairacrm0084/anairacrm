-- Existing OTA listing linking requests. This records the property's existing
-- OTA identity and owner consent without collecting OTA passwords or claiming
-- that a provider OAuth/API connection is already active.
create table if not exists public.anaira_ota_listing_link_requests (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  provider_code text not null,
  external_listing_id text not null,
  account_email text not null,
  channel_manager text not null default 'direct',
  status text not null default 'authorization_requested',
  owner_authorized_at timestamptz not null,
  requested_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  review_note text,
  linked_connection_id uuid references public.anaira_distribution_connections(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, provider_code, external_listing_id),
  constraint ana_ota_link_provider_chk check (provider_code in ('booking_com','airbnb','agoda','expedia','makemytrip','goibibo','trip_com','hostelworld')),
  constraint ana_ota_link_status_chk check (status in ('authorization_requested','awaiting_provider_approval','ready_for_oauth','connected','rejected','needs_information'))
);
create index if not exists ana_ota_link_requests_tenant_idx
  on public.anaira_ota_listing_link_requests(restaurant_id, created_at desc);
alter table public.anaira_ota_listing_link_requests enable row level security;
drop policy if exists ana_ota_link_request_tenant_select on public.anaira_ota_listing_link_requests;
create policy ana_ota_link_request_tenant_select on public.anaira_ota_listing_link_requests
  for select to authenticated
  using (public.anaira_tenant_access(restaurant_id) or public.anaira_current_is_super_admin());
drop policy if exists ana_ota_link_request_tenant_insert on public.anaira_ota_listing_link_requests;
create policy ana_ota_link_request_tenant_insert on public.anaira_ota_listing_link_requests
  for insert to authenticated
  with check (public.anaira_tenant_access(restaurant_id) or public.anaira_current_is_super_admin());
drop policy if exists ana_ota_link_request_tenant_update on public.anaira_ota_listing_link_requests;
create policy ana_ota_link_request_tenant_update on public.anaira_ota_listing_link_requests
  for update to authenticated
  using (public.anaira_current_is_super_admin())
  with check (public.anaira_current_is_super_admin());
revoke all on public.anaira_ota_listing_link_requests from anon;
grant select, insert, update on public.anaira_ota_listing_link_requests to authenticated;
grant all on public.anaira_ota_listing_link_requests to service_role;
