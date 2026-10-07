-- ANAIRA Universal Business Capability Auto-Provisioning
-- 2026-10-06
--
-- Business Type rules:
-- hotel_resort     -> Hotel Store + Booking Engine
-- hotel_restaurant -> Hotel Store + Booking Engine + Restaurant Store
-- restaurant_cafe  -> Restaurant Store
--
-- Hospitality types supported by the canonical stay layer:
-- homestay, guest_house, cottage
-- Camp remains on the existing camping engine and is intentionally not
-- inserted into anaira_stay_properties because that table currently
-- enforces only homestay/guest_house/cottage.

create or replace function public.anaira_sync_business_capabilities()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  hotel_store uuid;
  restaurant_store uuid;
  wants_hotel boolean;
  wants_restaurant boolean;
  htypes text[];
  htype text;
begin
  wants_hotel :=
    coalesce(new.business_type,'') in ('hotel_resort','hotel_restaurant');

  wants_restaurant :=
    coalesce(new.business_type,'') in ('restaurant_cafe','hotel_restaurant');

  select id
    into hotel_store
  from public.anaira_platform_stores
  where store_type = 'hotel'
  order by created_at nulls last, id
  limit 1;

  select id
    into restaurant_store
  from public.anaira_platform_stores
  where store_type = 'restaurant'
  order by created_at nulls last, id
  limit 1;

  -- HOTEL CAPABILITY
  if wants_hotel and hotel_store is not null then

    insert into public.anaira_store_memberships
      (
        store_id,
        restaurant_id,
        enabled,
        sort_order,
        listing_override,
        catalog_source,
        manual_catalog_enabled,
        store_config,
        image_config,
        sync_status
      )
    values
      (
        hotel_store,
        new.id,
        true,
        0,
        '{}'::jsonb,
        'anaira_hms',
        false,
        '{}'::jsonb,
        '{}'::jsonb,
        'configured'
      )
    on conflict (store_id, restaurant_id)
    do update set
      enabled = true,
      catalog_source = 'anaira_hms',
      sync_status = 'configured';

    insert into public.booking_engine_settings
      (
        restaurant_id,
        template,
        locale,
        currency,
        multi_currency,
        multi_language,
        payment_mode,
        direct_booking_enabled,
        packages_enabled,
        addons_enabled,
        promo_enabled,
        guest_login_enabled,
        pay_at_hotel_enabled,
        bank_transfer_enabled,
        qr_upi_enabled,
        whatsapp_booking_enabled
      )
    values
      (
        new.id,
        'hotel',
        'en-IN',
        'INR',
        false,
        false,
        'pay_at_hotel',
        true,
        true,
        true,
        true,
        true,
        true,
        false,
        false,
        false
      )
    on conflict (restaurant_id)
    do update set
      direct_booking_enabled = true,
      updated_at = now();

    -- Multi-hospitality stay capabilities.
    -- Do NOT insert 'hotel'/'camp' into anaira_stay_properties because the
    -- current table CHECK constraint intentionally supports only these types.
    htypes := array(
      select distinct x
      from unnest(
        coalesce(
          nullif(new.hospitality_types, '{}'::text[]),
          array[coalesce(nullif(new.hospitality_type,''), 'hotel')]
        )
      ) x
      where x in ('homestay','guest_house','cottage')
    );

    foreach htype in array htypes loop
      insert into public.anaira_stay_properties
        (
          restaurant_id,
          stay_type,
          name,
          short_name,
          description,
          address,
          city,
          state,
          country,
          active,
          marketplace_visible
        )
      values
        (
          new.id,
          htype,
          coalesce(new.name, 'Property'),
          coalesce(new.name, 'Property'),
          coalesce(new.description, ''),
          coalesce(new.address, ''),
          coalesce(new.city, ''),
          coalesce(new.state, ''),
          coalesce(new.country, 'India'),
          true,
          true
        )
      on conflict (restaurant_id, stay_type)
      do update set
        name = excluded.name,
        active = true,
        marketplace_visible = true,
        updated_at = now();
    end loop;

  elsif hotel_store is not null then

    update public.anaira_store_memberships
    set enabled = false
    where store_id = hotel_store
      and restaurant_id = new.id;

  end if;

  -- RESTAURANT CAPABILITY
  if wants_restaurant and restaurant_store is not null then

    insert into public.anaira_store_memberships
      (
        store_id,
        restaurant_id,
        enabled,
        sort_order,
        listing_override,
        catalog_source,
        manual_catalog_enabled,
        store_config,
        image_config,
        sync_status
      )
    values
      (
        restaurant_store,
        new.id,
        true,
        0,
        '{}'::jsonb,
        'restaurant_saas',
        false,
        '{}'::jsonb,
        '{}'::jsonb,
        'configured'
      )
    on conflict (store_id, restaurant_id)
    do update set
      enabled = true,
      catalog_source = 'restaurant_saas',
      sync_status = 'configured';

  elsif restaurant_store is not null then

    update public.anaira_store_memberships
    set enabled = false
    where store_id = restaurant_store
      and restaurant_id = new.id;

  end if;

  return new;
end;
$$;

drop trigger if exists trg_anaira_sync_business_capabilities
on public.restaurants;

create trigger trg_anaira_sync_business_capabilities
after insert or update of
  business_type,
  hospitality_type,
  hospitality_types,
  name,
  address,
  city,
  state,
  country,
  description
on public.restaurants
for each row
execute function public.anaira_sync_business_capabilities();

grant execute on function public.anaira_sync_business_capabilities()
to authenticated;

-- Backfill all existing businesses.
-- The no-op assignment fires the trigger for every existing row.
update public.restaurants
set business_type = business_type
where id is not null;
