-- Hotel profile/master + payment runtime alignment.
-- 1) Ensure hotel properties automatically get a canonical hospitality master row.
-- 2) Repair the current hotel tenant if it was created before the master sync existed.
-- 3) Keep the existing hms_booking_payment_submissions table as the canonical payment-submission table.

create or replace function public.anaira_sync_business_capabilities()
returns trigger
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  hotel_store uuid;
  restaurant_store uuid;
  wants_hotel boolean;
  wants_restaurant boolean;
  htypes text[];
  htype text;
begin
  wants_hotel := coalesce(new.business_type,'') in ('hotel_resort','hotel_restaurant');
  wants_restaurant := coalesce(new.business_type,'') in ('restaurant_cafe','hotel_restaurant');

  -- Always resolve the platform parent by store_type + platform ownership.
  select id into hotel_store
  from public.anaira_platform_stores
  where restaurant_id is null and is_platform_store=true and store_type='hotel'
  order by created_at nulls last,id limit 1;

  select id into restaurant_store
  from public.anaira_platform_stores
  where restaurant_id is null and is_platform_store=true and store_type='restaurant'
  order by created_at nulls last,id limit 1;

  if wants_hotel then
    -- Canonical property master: one row per live restaurant tenant.
    insert into public.anaira_hospitality_properties_master
      (tenant_id,source_table,source_id,property_type,name,destination,city,state,country,active,metadata,business_type,updated_at)
    values
      (new.id,'restaurants',new.id,
       case when coalesce(new.hospitality_type,'hotel') in ('camp','homestay','guest_house','cottage')
            then coalesce(new.hospitality_type,'hotel') else 'hotel' end,
       coalesce(new.name,'Property'),
       nullif(coalesce(new.city,''),''),new.city,new.state,coalesce(new.country,'India'),
       coalesce(new.status,'active')='active',
       jsonb_build_object('hospitality_types',coalesce(new.hospitality_types,array[coalesce(new.hospitality_type,'hotel')])),
       new.business_type,now())
    on conflict (tenant_id) do update set
      source_table=excluded.source_table,
      source_id=excluded.source_id,
      property_type=excluded.property_type,
      name=excluded.name,
      city=excluded.city,
      state=excluded.state,
      country=excluded.country,
      active=excluded.active,
      metadata=excluded.metadata,
      business_type=excluded.business_type,
      updated_at=now();

    if hotel_store is not null then
      insert into public.anaira_store_memberships
        (store_id,restaurant_id,enabled,sort_order,listing_override,catalog_source,manual_catalog_enabled,store_config,image_config,sync_status)
      values (hotel_store,new.id,true,0,'{}'::jsonb,'anaira_hms',false,'{}'::jsonb,'{}'::jsonb,'configured')
      on conflict (store_id,restaurant_id) do update set enabled=true,catalog_source='anaira_hms',sync_status='configured';
    end if;

    insert into public.booking_engine_settings
      (restaurant_id,template,locale,currency,multi_currency,multi_language,payment_mode,direct_booking_enabled,packages_enabled,addons_enabled,promo_enabled,guest_login_enabled,pay_at_hotel_enabled,bank_transfer_enabled,qr_upi_enabled,whatsapp_booking_enabled)
    values (new.id,'hotel','en-IN','INR',false,false,'pay_at_hotel',true,true,true,true,true,true,false,false,false)
    on conflict (restaurant_id) do update set direct_booking_enabled=true,updated_at=now();

    htypes := array(select distinct x from unnest(coalesce(nullif(new.hospitality_types,'{}'::text[]),array[coalesce(nullif(new.hospitality_type,''),'hotel')])) x where x in ('homestay','guest_house','cottage'));
    foreach htype in array htypes loop
      insert into public.anaira_stay_properties
        (restaurant_id,stay_type,name,short_name,description,address,city,state,country,active,marketplace_visible)
      values (new.id,htype,coalesce(new.name,'Property'),coalesce(new.name,'Property'),coalesce(new.description,''),coalesce(new.address,''),coalesce(new.city,''),coalesce(new.state,''),coalesce(new.country,'India'),true,true)
      on conflict (restaurant_id,stay_type) do update set name=excluded.name,active=true,marketplace_visible=true,updated_at=now();
    end loop;
  else
    if hotel_store is not null then
      update public.anaira_store_memberships set enabled=false where store_id=hotel_store and restaurant_id=new.id;
    end if;
    update public.anaira_hospitality_properties_master set active=false,updated_at=now() where tenant_id=new.id;
  end if;

  if wants_restaurant then
    if restaurant_store is not null then
      insert into public.anaira_store_memberships
        (store_id,restaurant_id,enabled,sort_order,listing_override,catalog_source,manual_catalog_enabled,store_config,image_config,sync_status)
      values (restaurant_store,new.id,true,0,'{}'::jsonb,'restaurant_saas',false,'{}'::jsonb,'{}'::jsonb,'configured')
      on conflict (store_id,restaurant_id) do update set enabled=true,catalog_source='restaurant_saas',sync_status='configured';
    end if;
  elsif restaurant_store is not null then
    update public.anaira_store_memberships set enabled=false where store_id=restaurant_store and restaurant_id=new.id;
  end if;

  return new;
end;
$$;

-- Current NH3 HOTEL tenant was created before the master-sync trigger was repaired.
insert into public.anaira_hospitality_properties_master
  (tenant_id,source_table,source_id,property_type,name,city,state,country,active,metadata,business_type)
select id,'restaurants',id,coalesce(nullif(hospitality_type,''),'hotel'),name,city,state,coalesce(country,'India'),coalesce(status,'active')='active',jsonb_build_object('hospitality_types',coalesce(hospitality_types,array[coalesce(hospitality_type,'hotel')])),business_type
from public.restaurants
where id='a4569eac-5ed1-4136-b32f-356a02531073'
on conflict (tenant_id) do update set name=excluded.name,property_type=excluded.property_type,city=excluded.city,state=excluded.state,country=excluded.country,active=excluded.active,metadata=excluded.metadata,business_type=excluded.business_type,updated_at=now();

-- Canonical payment submissions are already implemented as hms_booking_payment_submissions.
-- Do not create a second competing payment table. The application runtime now reads this table.
