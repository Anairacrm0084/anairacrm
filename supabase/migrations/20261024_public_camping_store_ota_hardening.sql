-- Anaira public camping booking + OTA registry hardening.
-- Non-destructive: never invent tent counts, prices, or inventory dates.

-- Make sure the two known camp properties have public property profiles.
-- Existing operator-provided details win; only empty/missing values are filled.
insert into public.camp_properties
  (restaurant_id, name, short_name, description, destination, address, city, state, country,
   logo_url, cover_image_url, active, marketplace_visible, check_in_time, check_out_time)
select r.id,
       r.name,
       r.name,
       'Camping accommodation in Himachal Pradesh.',
       coalesce(nullif(r.city,''), 'Kullu'),
       nullif(r.address,''),
       coalesce(nullif(r.city,''), 'Kullu'),
       'Himachal Pradesh', 'India',
       nullif(r.logo,''), nullif(r.cover_image,''), true, true, '12:00', '11:00'
from public.restaurants r
where lower(coalesce(r.hospitality_type,''))='camp'
   or lower(coalesce(r.name,'')) like '%camp%'
on conflict (restaurant_id) do update set
  name = coalesce(nullif(public.camp_properties.name,''), excluded.name),
  short_name = coalesce(nullif(public.camp_properties.short_name,''), excluded.short_name),
  description = coalesce(nullif(public.camp_properties.description,''), excluded.description),
  destination = coalesce(nullif(public.camp_properties.destination,''), excluded.destination),
  address = coalesce(nullif(public.camp_properties.address,''), excluded.address),
  city = coalesce(nullif(public.camp_properties.city,''), excluded.city),
  state = coalesce(nullif(public.camp_properties.state,''), excluded.state),
  country = coalesce(nullif(public.camp_properties.country,''), excluded.country),
  logo_url = coalesce(nullif(public.camp_properties.logo_url,''), excluded.logo_url),
  cover_image_url = coalesce(nullif(public.camp_properties.cover_image_url,''), excluded.cover_image_url),
  updated_at = now();

-- Public users may read only published camp profile/catalog rows.
alter table public.camp_properties enable row level security;
alter table public.camp_unit_types enable row level security;
alter table public.camp_rate_plans enable row level security;

drop policy if exists camp_properties_public_select on public.camp_properties;
create policy camp_properties_public_select on public.camp_properties
  for select to anon, authenticated using (active = true and marketplace_visible = true);

drop policy if exists camp_unit_types_public_select on public.camp_unit_types;
create policy camp_unit_types_public_select on public.camp_unit_types
  for select to anon, authenticated using (
    active = true and exists (
      select 1 from public.camp_properties p
      where p.restaurant_id = camp_unit_types.restaurant_id
        and p.active = true and p.marketplace_visible = true
    )
  );

drop policy if exists camp_rate_plans_public_select on public.camp_rate_plans;
create policy camp_rate_plans_public_select on public.camp_rate_plans
  for select to anon, authenticated using (
    active = true and exists (
      select 1 from public.camp_properties p
      where p.restaurant_id = camp_rate_plans.restaurant_id
        and p.active = true and p.marketplace_visible = true
    )
  );

-- OTA table columns are additive to support older deployments without exposing secrets.
alter table public.ota_channels add column if not exists property_id uuid;
alter table public.ota_channels add column if not exists auto_sync boolean not null default false;
alter table public.ota_channels add column if not exists last_error text;
alter table public.ota_channels add column if not exists connected_at timestamptz;
alter table public.ota_channels add column if not exists platform_id uuid;
alter table public.ota_channels add column if not exists settings jsonb not null default '{}'::jsonb;
alter table public.ota_channels add column if not exists credentials_ref text;
alter table public.ota_channels add column if not exists last_sync_at timestamptz;
alter table public.ota_channels add column if not exists status text not null default 'disconnected';
alter table public.ota_channels enable row level security;
alter table public.ota_room_mappings enable row level security;
alter table public.ota_rate_mappings enable row level security;
alter table public.ota_sync_events enable row level security;

drop policy if exists ota_channels_tenant_manage on public.ota_channels;
create policy ota_channels_tenant_manage on public.ota_channels
  for all to authenticated
  using (public.anaira_tenant_access(restaurant_id))
  with check (public.anaira_tenant_access(restaurant_id));

drop policy if exists ota_room_mappings_tenant_manage on public.ota_room_mappings;
create policy ota_room_mappings_tenant_manage on public.ota_room_mappings
  for all to authenticated
  using (exists (select 1 from public.ota_channels c where c.id=ota_room_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)))
  with check (exists (select 1 from public.ota_channels c where c.id=ota_room_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)));

drop policy if exists ota_rate_mappings_tenant_manage on public.ota_rate_mappings;
create policy ota_rate_mappings_tenant_manage on public.ota_rate_mappings
  for all to authenticated
  using (exists (select 1 from public.ota_channels c where c.id=ota_rate_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)))
  with check (exists (select 1 from public.ota_channels c where c.id=ota_rate_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)));

drop policy if exists ota_sync_events_tenant_manage on public.ota_sync_events;
create policy ota_sync_events_tenant_manage on public.ota_sync_events
  for all to authenticated
  using (public.anaira_tenant_access(restaurant_id))
  with check (public.anaira_tenant_access(restaurant_id));

create index if not exists ota_channels_tenant_status_idx on public.ota_channels(restaurant_id,status);
create index if not exists ota_sync_events_tenant_created_idx on public.ota_sync_events(restaurant_id,created_at desc);
notify pgrst, 'reload schema';
