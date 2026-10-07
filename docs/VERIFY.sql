-- Verification queries for universal business capability provisioning.

select
  r.id,
  r.name,
  r.business_type,
  r.hospitality_type,
  r.hospitality_types,
  h.enabled as hotel_store_enabled,
  h.catalog_source as hotel_catalog_source,
  rest.enabled as restaurant_store_enabled,
  rest.catalog_source as restaurant_catalog_source,
  bes.direct_booking_enabled
from public.restaurants r
left join public.anaira_store_memberships h
  on h.restaurant_id = r.id
 and h.store_id = (
   select id from public.anaira_platform_stores
   where store_type='hotel'
   order by created_at nulls last, id
   limit 1
 )
left join public.anaira_store_memberships rest
  on rest.restaurant_id = r.id
 and rest.store_id = (
   select id from public.anaira_platform_stores
   where store_type='restaurant'
   order by created_at nulls last, id
   limit 1
 )
left join public.booking_engine_settings bes
  on bes.restaurant_id = r.id
order by r.created_at desc;
