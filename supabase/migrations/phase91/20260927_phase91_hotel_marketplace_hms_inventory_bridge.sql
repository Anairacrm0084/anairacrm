-- Phase 91: marketplace hotel availability reads canonical HMS availability.
create or replace function public.anaira_marketplace_hotel_search(p_check_in date, p_check_out date, p_adults integer default 2, p_children integer default 0, p_destination text default null)
returns table(restaurant_id uuid, hotel_name text, city text, address text, logo text, cover_image text, listing_override jsonb, available_room_types bigint)
language sql stable security definer set search_path = public, pg_temp as $function$
  select r.id,r.name,r.city,r.address,r.logo,r.cover_image,coalesce(m.listing_override,'{}'::jsonb),coalesce(av.available_room_types,0)::bigint
  from public.anaira_store_memberships m
  join public.anaira_platform_stores s on s.id=m.store_id and s.store_type='hotel' and s.enabled=true and s.published=true
  join public.restaurants r on r.id=m.restaurant_id
  left join lateral (select count(*)::bigint as available_room_types from public.anaira_public_hms_room_availability(r.id,p_check_in,p_check_out,p_adults,p_children) a) av on true
  where m.enabled=true and (p_destination is null or trim(p_destination)='' or lower(concat_ws(' ',r.name,r.city,r.address)) like '%'||lower(trim(p_destination))||'%')
  order by m.sort_order,r.name;
$function$;
