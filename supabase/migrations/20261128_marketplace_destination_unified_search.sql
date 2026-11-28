-- Make destination selection consistent across all marketplace accommodation types.
-- Destination cards remain platform-owned; property locations stay in their canonical tables.

create or replace function public.anaira_marketplace_camp_search(
  p_check_in date,
  p_check_out date,
  p_adults integer default 1,
  p_children integer default 0,
  p_destination text default null
)
returns table(
  restaurant_id uuid, property_name text, destination text, city text,
  unit_type_id uuid, unit_name text, rate_plan_id uuid, rate_name text,
  pricing_mode text, rate numeric, available_units integer,
  max_guests integer, max_adults integer, max_children integer, cover_image_url text
)
language sql
security definer
set search_path = ''
as $function$
 select p.restaurant_id,p.name,p.destination,p.city,u.id,u.name,r.id,r.name,r.pricing_mode,r.rate,
 case when u.id is null or r.id is null or p_check_in is null or p_check_out is null or p_check_out<=p_check_in then 0
 else greatest(0,least(u.unit_count,coalesce((select min(i.total_units-i.sold_units-i.held_units-i.blocked_units)
  from public.camp_inventory i where i.unit_type_id=u.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),0)))::int end,
 u.max_guests,u.max_adults,u.max_children,
 coalesce(nullif(p.cover_image_url,''),nullif(hs.cover_image_url,''),nullif(rest.cover_image,''), 
   (select nullif(ps.cover_url,'') from public.anaira_platform_stores ps
     where ps.restaurant_id=p.restaurant_id and ps.store_type='hotel' and ps.is_platform_store=false
     order by ps.updated_at desc limit 1))
 from public.camp_properties p
 join public.anaira_businesses biz on biz.business_id=p.restaurant_id and biz.hospitality_type='camp'
 join public.restaurants rest on rest.id=p.restaurant_id
 left join public.hms_settings hs on hs.restaurant_id=p.restaurant_id
 left join public.camp_unit_types u on u.restaurant_id=p.restaurant_id and u.active
 left join lateral(select rp.* from public.camp_rate_plans rp where rp.unit_type_id=u.id and rp.restaurant_id=p.restaurant_id and rp.active order by rp.rate limit 1) r on true
 where p.active and p.marketplace_visible
 and exists(select 1 from public.anaira_platform_stores s where s.restaurant_id=p.restaurant_id and s.store_type='hotel'
  and s.is_platform_store=false and s.enabled=true and s.published=true and s.marketplace_approval_status='approved')
 and (
   nullif(trim(p_destination),'') is null
   or exists(
     select 1 from public.anaira_hotel_store_destinations d
     where d.active=true and lower(trim(d.name))=lower(trim(p_destination))
       and (
         hs.marketplace_destination_id=d.id
         or lower(trim(coalesce(p.destination,'')))=lower(trim(d.name))
         or lower(trim(coalesce(p.city,'')))=lower(trim(d.name))
         or lower(concat_ws(' ',p.name,p.destination,p.city,p.address,rest.city,rest.address)) like '%'||lower(trim(d.name))||'%'
       )
   )
   or lower(concat_ws(' ',p.name,p.destination,p.city,p.address,rest.name,rest.city,rest.address)) like '%'||lower(trim(p_destination))||'%'
 )
 and (u.id is null or (p_adults>=1 and p_adults<=u.max_adults and p_children>=0 and p_children<=u.max_children and p_adults+p_children<=u.max_guests))
 order by p.name,u.name;
$function$;

create or replace function public.anaira_marketplace_stay_search(
  p_stay_type text,
  p_check_in date,
  p_check_out date,
  p_adults integer default 1,
  p_children integer default 0,
  p_destination text default null
)
returns table(
  restaurant_id uuid, property_id uuid, stay_type text, property_name text, destination text, city text,
  unit_type_id uuid, unit_name text, rate_plan_id uuid, rate_name text, pricing_mode text, rate numeric,
  available_units integer, max_guests integer, max_adults integer, max_children integer, cover_image_url text
)
language sql
security definer
set search_path = ''
as $function$
  select
    r.id as restaurant_id,
    p.id as property_id,
    p.stay_type,
    coalesce(nullif(p.name,''),r.name) as property_name,
    coalesce(nullif(p.destination,''),nullif(d.name,''),nullif(p.city,''),nullif(r.city,''),nullif(p.address,''),nullif(r.address,'')) as destination,
    coalesce(nullif(p.city,''),nullif(r.city,''),nullif(p.address,''),nullif(r.address,'')) as city,
    rt.id as unit_type_id,
    rt.name as unit_name,
    rp.id as rate_plan_id,
    rp.name as rate_name,
    coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit') as pricing_mode,
    coalesce(rp.rate,rt.base_rate,0)::numeric as rate,
    avail.available_units::integer,
    coalesce(rt.max_guests,rt.max_adults+coalesce(rt.max_children,0),rt.max_adults,1)::integer as max_guests,
    coalesce(rt.max_adults,1)::integer as max_adults,
    coalesce(rt.max_children,0)::integer as max_children,
    coalesce(nullif(p.cover_image_url,''),nullif(hs.cover_image_url,''),nullif(r.cover_image,''), 
      (select nullif(ps.cover_url,'') from public.anaira_platform_stores ps
       where ps.restaurant_id=r.id and ps.store_type='hotel' and ps.is_platform_store=false
       order by ps.updated_at desc limit 1)) as cover_image_url
  from public.anaira_stay_properties p
  join public.restaurants r
    on r.id=p.restaurant_id
   and coalesce(r.status,'active')='active'
   and coalesce(r.hospitality_type,'hotel')=p.stay_type
  join public.hms_room_types rt
    on rt.restaurant_id=r.id and rt.hospitality_type=p.stay_type and rt.active=true
  join public.hms_rate_plans rp
    on rp.restaurant_id=r.id and rp.room_type_id=rt.id and rp.hospitality_type=p.stay_type and rp.active=true
  left join public.hms_settings hs on hs.restaurant_id=r.id
  left join public.anaira_hotel_store_destinations d
    on d.id=hs.marketplace_destination_id and d.active=true
  cross join lateral (
    select case
      when count(i.id)=greatest(1,p_check_out-p_check_in)
        then min(greatest(0,i.total_rooms-i.sold_rooms-i.blocked_rooms))
      else 0
    end as available_units
    from public.hms_inventory i
    where i.restaurant_id=r.id and i.room_type_id=rt.id
      and i.stay_date>=p_check_in and i.stay_date<p_check_out
      and not coalesce(i.closed,false) and not coalesce(i.stop_sell,false)
  ) avail
  where p.stay_type=p_stay_type
    and p.active=true and p.marketplace_visible=true
    and exists(select 1 from public.anaira_platform_stores s where s.restaurant_id=r.id and s.store_type='hotel'
      and s.is_platform_store=false and s.enabled=true and s.published=true and s.marketplace_approval_status='approved')
    and p_check_out>p_check_in and p_adults>=1 and p_children>=0
    and p_adults<=coalesce(rt.max_adults,1)
    and p_children<=coalesce(rt.max_children,0)
    and p_adults+p_children<=coalesce(rt.max_guests,rt.max_adults+coalesce(rt.max_children,0),rt.max_adults,1)
    and avail.available_units>0
    and (
      nullif(trim(p_destination),'') is null
      or (d.id is not null and lower(trim(d.name))=lower(trim(p_destination)))
      or coalesce(p.destination,'') ilike '%'||trim(p_destination)||'%'
      or coalesce(p.city,'') ilike '%'||trim(p_destination)||'%'
      or coalesce(r.city,'') ilike '%'||trim(p_destination)||'%'
      or coalesce(p.address,'') ilike '%'||trim(p_destination)||'%'
      or coalesce(r.address,'') ilike '%'||trim(p_destination)||'%'
      or coalesce(p.name,'') ilike '%'||trim(p_destination)||'%'
      or coalesce(r.name,'') ilike '%'||trim(p_destination)||'%'
    )
  order by p.name,rt.name,rp.rate;
$function$;

grant execute on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) to anon,authenticated;
grant execute on function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) to anon,authenticated;
