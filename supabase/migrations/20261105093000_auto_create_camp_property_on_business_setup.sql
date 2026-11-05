-- Automatically provision the canonical Camping property profile when a business
-- is created or converted to hospitality_type='camp'. restaurants remains a
-- compatibility tenant table until the staged FK migration is completed.
create or replace function public.anaira_sync_business_capabilities()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $function$
declare
 hotel_store uuid; restaurant_store uuid; wants_hotel boolean; wants_restaurant boolean;
 htypes text[]; htype text; master_id uuid;
begin
 wants_hotel := coalesce(new.business_type,'') in ('hotel_resort','hotel_restaurant')
   or coalesce(new.hospitality_type,'') in ('hotel','camp','homestay','guest_house','cottage')
   or coalesce(new.hospitality_types,array[]::text[]) && array['hotel','camp','homestay','guest_house','cottage']::text[];
 wants_restaurant := coalesce(new.business_type,'') in ('restaurant_cafe','hotel_restaurant');
 select id into hotel_store from public.anaira_platform_stores where restaurant_id is null and is_platform_store=true and store_type='hotel' order by created_at nulls last,id limit 1;
 select id into restaurant_store from public.anaira_platform_stores where restaurant_id is null and is_platform_store=true and store_type='restaurant' order by created_at nulls last,id limit 1;
 if wants_hotel then
   select id into master_id from public.anaira_hospitality_properties_master where source_table='restaurants' and source_id=new.id limit 1;
   if master_id is null then
     insert into public.anaira_hospitality_properties_master(tenant_id,source_table,source_id,property_type,name,destination,city,state,country,active,metadata,business_type)
     values(new.id,'restaurants',new.id,case when coalesce(new.hospitality_type,'hotel') in ('camp','homestay','guest_house','cottage') then new.hospitality_type else 'hotel' end,coalesce(new.name,'Property'),nullif(coalesce(new.city,''),''),new.city,new.state,coalesce(new.country,'India'),coalesce(new.status,'active')='active',jsonb_build_object('hospitality_types',coalesce(new.hospitality_types,array[coalesce(new.hospitality_type,'hotel')])),new.business_type)
     returning id into master_id;
   else
     update public.anaira_hospitality_properties_master set tenant_id=new.id,property_type=case when coalesce(new.hospitality_type,'hotel') in ('camp','homestay','guest_house','cottage') then new.hospitality_type else 'hotel' end,name=coalesce(new.name,'Property'),destination=nullif(coalesce(new.city,''),''),city=new.city,state=new.state,country=coalesce(new.country,'India'),active=coalesce(new.status,'active')='active',metadata=jsonb_build_object('hospitality_types',coalesce(new.hospitality_types,array[coalesce(new.hospitality_type,'hotel')])),business_type=new.business_type,updated_at=now() where id=master_id;
   end if;
   if hotel_store is not null then
     insert into public.anaira_store_memberships(store_id,restaurant_id,enabled,sort_order,listing_override,catalog_source,manual_catalog_enabled,store_config,image_config,sync_status)
     values(hotel_store,new.id,true,0,'{}'::jsonb,'anaira_hms',false,'{}'::jsonb,'{}'::jsonb,'configured')
     on conflict(store_id,restaurant_id) do update set enabled=true,catalog_source='anaira_hms',sync_status='configured';
   end if;
   insert into public.booking_engine_settings(restaurant_id,template,locale,currency,multi_currency,multi_language,payment_mode,direct_booking_enabled,packages_enabled,addons_enabled,promo_enabled,guest_login_enabled,pay_at_hotel_enabled,bank_transfer_enabled,qr_upi_enabled,whatsapp_booking_enabled)
   values(new.id,'hotel','en-IN','INR',false,false,'pay_at_hotel',true,true,true,true,true,true,false,false,false)
   on conflict(restaurant_id) do update set direct_booking_enabled=true,updated_at=now();
   if coalesce(new.hospitality_type,'') in ('camp','camping') or coalesce(new.hospitality_types,array[]::text[]) && array['camp','camping']::text[] then
     insert into public.camp_properties(restaurant_id,name,short_name,description,destination,address,city,state,country,latitude,longitude,logo_url,cover_image_url,gallery,active,marketplace_visible)
     values(new.id,coalesce(new.name,'Camping Property'),coalesce(new.name,'Camping Property'),coalesce(new.description,''),nullif(coalesce(new.city,''),''),coalesce(new.address,''),coalesce(new.city,''),coalesce(new.state,'Himachal Pradesh'),coalesce(new.country,'India'),new.latitude,new.longitude,new.logo,new.cover_image,'[]'::jsonb,coalesce(new.status,'active')='active',false)
     on conflict(restaurant_id) do update set name=excluded.name,address=coalesce(nullif(public.camp_properties.address,''),excluded.address),city=coalesce(nullif(public.camp_properties.city,''),excluded.city),state=coalesce(nullif(public.camp_properties.state,''),excluded.state),country=coalesce(nullif(public.camp_properties.country,''),excluded.country),active=excluded.active,updated_at=now();
   end if;
   htypes:=array(select distinct x from unnest(coalesce(nullif(new.hospitality_types,'{}'::text[]),array[coalesce(nullif(new.hospitality_type,''),'hotel')])) x where x in ('homestay','guest_house','cottage'));
   foreach htype in array htypes loop
     insert into public.anaira_stay_properties(restaurant_id,stay_type,name,short_name,description,address,city,state,country,active,marketplace_visible)
     values(new.id,htype,coalesce(new.name,'Property'),coalesce(new.name,'Property'),coalesce(new.description,''),coalesce(new.address,''),coalesce(new.city,''),coalesce(new.state,''),coalesce(new.country,'India'),true,false)
     on conflict(restaurant_id,stay_type) do update set name=excluded.name,active=true,updated_at=now();
   end loop;
 else
   if hotel_store is not null then update public.anaira_store_memberships set enabled=false where store_id=hotel_store and restaurant_id=new.id; end if;
   update public.anaira_hospitality_properties_master set active=false,updated_at=now() where tenant_id=new.id;
 end if;
 if wants_restaurant then
   if restaurant_store is not null then
     insert into public.anaira_store_memberships(store_id,restaurant_id,enabled,sort_order,listing_override,catalog_source,manual_catalog_enabled,store_config,image_config,sync_status)
     values(restaurant_store,new.id,true,0,'{}'::jsonb,'restaurant_saas',false,'{}'::jsonb,'{}'::jsonb,'configured')
     on conflict(store_id,restaurant_id) do update set enabled=true,catalog_source='restaurant_saas',sync_status='configured';
   end if;
 elsif restaurant_store is not null then update public.anaira_store_memberships set enabled=false where store_id=restaurant_store and restaurant_id=new.id; end if;
 return new;
end;
$function$;
notify pgrst,'reload schema';
