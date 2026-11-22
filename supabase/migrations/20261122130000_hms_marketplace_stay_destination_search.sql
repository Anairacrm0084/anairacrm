-- Marketplace stay search: use canonical HMS room/rate/inventory data
-- and include the property's postal address in destination matching.
-- This does not copy or duplicate room, rate, or inventory records.

create or replace function public.anaira_marketplace_stay_search(
  p_stay_type text,
  p_check_in date,
  p_check_out date,
  p_adults integer default 1,
  p_children integer default 0,
  p_destination text default null
)
returns table(
  restaurant_id uuid,
  property_id uuid,
  stay_type text,
  property_name text,
  destination text,
  city text,
  unit_type_id uuid,
  unit_name text,
  rate_plan_id uuid,
  rate_name text,
  pricing_mode text,
  rate numeric,
  available_units integer,
  max_guests integer,
  max_adults integer,
  max_children integer,
  cover_image_url text
)
language sql
security definer
set search_path = public, pg_temp
as $function$
  select
    r.id as restaurant_id,
    p.id as property_id,
    p.stay_type,
    coalesce(nullif(p.name,''),r.name) as property_name,
    coalesce(
      nullif(p.destination,''),
      nullif(p.city,''),
      nullif(r.city,''),
      nullif(p.address,''),
      nullif(r.address,'')
    ) as destination,
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
    coalesce(p.cover_image_url,r.cover_image) as cover_image_url
  from public.anaira_stay_properties p
  join public.restaurants r
    on r.id=p.restaurant_id
   and coalesce(r.status,'active')='active'
   and coalesce(r.hospitality_type,'hotel')=p.stay_type
  join public.hms_room_types rt
    on rt.restaurant_id=r.id
   and rt.hospitality_type=p.stay_type
   and rt.active=true
  join public.hms_rate_plans rp
    on rp.restaurant_id=r.id
   and rp.room_type_id=rt.id
   and rp.hospitality_type=p.stay_type
   and rp.active=true
  cross join lateral (
    select
      case
        when count(i.id)=greatest(1,p_check_out-p_check_in)
          then min(greatest(0,i.total_rooms-i.sold_rooms-i.blocked_rooms))
        else 0
      end as available_units
    from public.hms_inventory i
    where i.restaurant_id=r.id
      and i.room_type_id=rt.id
      and i.stay_date>=p_check_in
      and i.stay_date<p_check_out
      and not coalesce(i.closed,false)
      and not coalesce(i.stop_sell,false)
  ) avail
  where p.stay_type=p_stay_type
    and p.active=true
    and p.marketplace_visible=true
    and p_check_out>p_check_in
    and p_adults>=1
    and p_children>=0
    and p_adults<=coalesce(rt.max_adults,1)
    and p_children<=coalesce(rt.max_children,0)
    and p_adults+p_children<=coalesce(rt.max_guests,rt.max_adults+coalesce(rt.max_children,0),rt.max_adults,1)
    and avail.available_units>0
    and (
      p_destination is null
      or coalesce(p.destination,'') ilike '%'||p_destination||'%'
      or coalesce(p.city,'') ilike '%'||p_destination||'%'
      or coalesce(r.city,'') ilike '%'||p_destination||'%'
      or coalesce(p.address,'') ilike '%'||p_destination||'%'
      or coalesce(r.address,'') ilike '%'||p_destination||'%'
      or p.name ilike '%'||p_destination||'%'
    )
  order by p.name,rt.name,rp.rate;
$function$;

grant execute on function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) to anon, authenticated;
