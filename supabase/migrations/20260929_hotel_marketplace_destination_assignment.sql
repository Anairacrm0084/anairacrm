-- Hotel -> ANAIRA Hotels destination assignment.
-- Preserves existing HMS, marketplace and booking flows.
alter table public.hms_settings
  add column if not exists marketplace_destination_id uuid references public.anaira_hotel_store_destinations(id) on delete set null;

create index if not exists hms_settings_marketplace_destination_idx
  on public.hms_settings(marketplace_destination_id);

-- The live marketplace search already supports destination assignment through
-- hms_settings.marketplace_destination_id. This migration only guarantees the
-- column/index exist for fresh installs; it does not alter the search contract.
