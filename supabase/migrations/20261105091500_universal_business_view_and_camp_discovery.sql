-- Universal business read model. Keep restaurants as a compatibility table until
-- all legacy foreign keys and writes are migrated in a dedicated breaking release.
create or replace view public.anaira_businesses as
select id as business_id,name,slug,business_type,status,owner_id,owner_name,email,phone,whatsapp,
       address,city,state,country,postal_code,latitude,longitude,hospitality_type,hospitality_types,
       marketplace_visible,created_at,updated_at
from public.restaurants;

-- Backfill the two existing Camp businesses that were not represented in the
-- Camping property master. Do not fabricate units, rates, or availability.
insert into public.camp_properties
(restaurant_id,name,short_name,description,destination,address,city,state,country,latitude,longitude,logo_url,cover_image_url,gallery,active,marketplace_visible)
select r.id,r.name,r.name,null,
       case when r.name ilike '%fort%' then 'Jalori Pass' when r.name ilike '%adventure%' then 'Jibhi' else coalesce(r.city,'') end,
       r.address,r.city,coalesce(r.state,'Himachal Pradesh'),coalesce(r.country,'India'),
       r.latitude,r.longitude,r.logo,r.cover_image,'[]'::jsonb,true,true
from public.restaurants r
where r.id in ('a94e78bc-6a78-47c6-b530-c7a13268c2ff','b7bdd8b3-b009-46ae-bac2-6f35263eaca3')
  and r.hospitality_type='camp'
on conflict (restaurant_id) do update
set name=excluded.name,
    address=coalesce(public.camp_properties.address,excluded.address),
    city=coalesce(public.camp_properties.city,excluded.city),
    state=coalesce(public.camp_properties.state,excluded.state),
    country=coalesce(public.camp_properties.country,excluded.country),
    active=true,marketplace_visible=true,updated_at=now();

-- Show every published Camp property, including discovery-only rows while
-- the owner configures units/rates. Only configured units with rates are bookable.
create or replace function public.anaira_marketplace_camp_search(
 p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0,p_destination text default null
) returns table(
 restaurant_id uuid,property_name text,destination text,city text,unit_type_id uuid,unit_name text,
 rate_plan_id uuid,rate_name text,pricing_mode text,rate numeric,available_units integer,
 max_guests integer,max_adults integer,max_children integer,cover_image_url text
) language sql security definer set search_path=public,pg_temp as $$
 select p.restaurant_id,p.name,p.destination,p.city,u.id,u.name,r.id,r.name,r.pricing_mode,r.rate,
 case when u.id is null or r.id is null or p_check_in is null or p_check_out is null or p_check_out<=p_check_in then 0
 else greatest(0,least(u.unit_count,coalesce((select min(i.total_units-i.sold_units-i.held_units-i.blocked_units)
      from public.camp_inventory i where i.unit_type_id=u.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),0)))::int end,
 u.max_guests,u.max_adults,u.max_children,p.cover_image_url
 from public.camp_properties p
 join public.anaira_businesses biz on biz.business_id=p.restaurant_id and biz.hospitality_type='camp'
 left join public.camp_unit_types u on u.restaurant_id=p.restaurant_id and u.active
 left join lateral(select rp.* from public.camp_rate_plans rp where rp.unit_type_id=u.id and rp.restaurant_id=p.restaurant_id and rp.active order by rp.rate limit 1) r on true
 where p.active and p.marketplace_visible
 and (p_destination is null or p.destination ilike '%'||p_destination||'%' or p.city ilike '%'||p_destination||'%' or p.name ilike '%'||p_destination||'%')
 and (u.id is null or (p_adults>=1 and p_adults<=u.max_adults and p_children>=0 and p_children<=u.max_children and p_adults+p_children<=u.max_guests))
 order by p.name,u.name;
$$;
revoke all on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) from public;
grant execute on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) to anon,authenticated;
notify pgrst,'reload schema';
