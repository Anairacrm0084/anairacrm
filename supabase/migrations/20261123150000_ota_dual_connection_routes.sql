-- Dual route for existing OTA listings: centrally managed Anaira API or property-owned OTA account.
-- Existing records are preserved and default to property_managed.
alter table public.anaira_ota_listing_link_requests
  add column if not exists connection_mode text not null default 'property_managed';

alter table public.anaira_ota_listing_link_requests
  drop constraint if exists ana_ota_link_connection_mode_chk;
alter table public.anaira_ota_listing_link_requests
  add constraint ana_ota_link_connection_mode_chk
  check (connection_mode in ('anaira_managed','property_managed'));

create index if not exists ana_ota_link_mode_status_idx
  on public.anaira_ota_listing_link_requests(connection_mode,status,created_at desc);

comment on column public.anaira_ota_listing_link_requests.connection_mode is
  'anaira_managed uses a Super Admin managed provider account; property_managed uses the property owner’s own provider authorization. This field does not itself establish API connectivity.';
