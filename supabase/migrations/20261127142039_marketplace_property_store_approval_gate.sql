-- Explicit approval state for tenant hospitality stores in the central marketplace.
-- Previously published stores are grandfathered as approved to preserve their existing visibility.
alter table public.anaira_platform_stores
  add column if not exists marketplace_approval_status text not null default 'pending',
  add column if not exists marketplace_approved_at timestamptz,
  add column if not exists marketplace_approved_by uuid references auth.users(id) on delete set null;

alter table public.anaira_platform_stores
  drop constraint if exists ana_platform_store_marketplace_approval_chk;
alter table public.anaira_platform_stores
  add constraint ana_platform_store_marketplace_approval_chk
  check (marketplace_approval_status in ('pending','approved','rejected','suspended'));

create index if not exists ana_platform_store_marketplace_gate_idx
  on public.anaira_platform_stores(marketplace_approval_status,enabled,published,store_type)
  where is_platform_store=false;
create index if not exists ana_platform_store_marketplace_approved_by_idx
  on public.anaira_platform_stores(marketplace_approved_by) where marketplace_approved_by is not null;

update public.anaira_platform_stores
set marketplace_approval_status='approved',
    marketplace_approved_at=coalesce(marketplace_approved_at,updated_at,created_at,now())
where is_platform_store=false and store_type='hotel' and published=true
  and marketplace_approval_status='pending';

create or replace function public.anaira_marketplace_hotel_search(
  p_check_in date,p_check_out date,p_adults integer default 2,p_children integer default 0,p_destination text default null
) returns table(
  restaurant_id uuid,hotel_name text,city text,address text,logo text,cover_image text,listing_override jsonb,available_room_types bigint
) language sql stable security definer set search_path='' as $$
 select r.id,r.name,r.city,r.address,r.logo,r.cover_image,
 coalesce(m.listing_override,'{}'::jsonb),coalesce(av.available_room_types,0)::bigint
 from public.anaira_store_memberships m
 join public.anaira_platform_stores s on s.id=m.store_id and s.store_type='hotel'
  and s.enabled=true and s.published=true and s.is_platform_store=false
  and s.marketplace_approval_status='approved'
 join public.restaurants r on r.id=m.restaurant_id
 join public.hms_settings hs on hs.restaurant_id=r.id
 left join lateral(select count(*)::bigint as available_room_types
  from public.anaira_public_hms_room_availability(r.id,p_check_in,p_check_out,p_adults,p_children) a) av on true
 where m.enabled=true and coalesce(r.hospitality_type,'hotel')='hotel'
 and (p_destination is null or trim(p_destination)='' or
  lower(coalesce(hs.marketplace_destination_id::text,''))=lower(trim(p_destination)) or
  exists(select 1 from public.anaira_hotel_store_destinations d where d.id=hs.marketplace_destination_id and d.active=true and lower(d.name)=lower(trim(p_destination))) or
  lower(concat_ws(' ',r.name,r.city,r.address)) like '%'||lower(trim(p_destination))||'%')
 order by m.sort_order,r.name;
$$;

create or replace function public.anaira_marketplace_stay_search(
  p_stay_type text,p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0,p_destination text default null
) returns table(
  restaurant_id uuid,property_id uuid,stay_type text,property_name text,destination text,city text,
  unit_type_id uuid,unit_name text,rate_plan_id uuid,rate_name text,pricing_mode text,rate numeric,
  available_units integer,max_guests integer,max_adults integer,max_children integer,cover_image_url text
) language sql security definer set search_path='' as $$
 select r.id,p.id,p.stay_type,coalesce(nullif(p.name,''),r.name),
  coalesce(nullif(p.destination,''),nullif(p.city,''),nullif(r.city,''),nullif(p.address,''),nullif(r.address,'')),
  coalesce(nullif(p.city,''),nullif(r.city,''),nullif(p.address,''),nullif(r.address,'')),
  rt.id,rt.name,rp.id,rp.name,coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit'),
  coalesce(rp.rate,rt.base_rate,0)::numeric,avail.available_units::integer,
  coalesce(rt.max_guests,rt.max_adults+coalesce(rt.max_children,0),rt.max_adults,1)::integer,
  coalesce(rt.max_adults,1)::integer,coalesce(rt.max_children,0)::integer,coalesce(p.cover_image_url,r.cover_image)
 from public.anaira_stay_properties p
 join public.restaurants r on r.id=p.restaurant_id and coalesce(r.status,'active')='active' and coalesce(r.hospitality_type,'hotel')=p.stay_type
 join public.hms_room_types rt on rt.restaurant_id=r.id and rt.hospitality_type=p.stay_type and rt.active=true
 join public.hms_rate_plans rp on rp.restaurant_id=r.id and rp.room_type_id=rt.id and rp.hospitality_type=p.stay_type and rp.active=true
 cross join lateral(select case when count(i.id)=greatest(1,p_check_out-p_check_in)
  then min(greatest(0,i.total_rooms-i.sold_rooms-i.blocked_rooms)) else 0 end as available_units
  from public.hms_inventory i where i.restaurant_id=r.id and i.room_type_id=rt.id
   and i.stay_date>=p_check_in and i.stay_date<p_check_out and not coalesce(i.closed,false) and not coalesce(i.stop_sell,false)) avail
 where p.stay_type=p_stay_type and p.active=true and p.marketplace_visible=true
 and exists(select 1 from public.anaira_platform_stores s where s.restaurant_id=r.id and s.store_type='hotel'
  and s.is_platform_store=false and s.enabled=true and s.published=true and s.marketplace_approval_status='approved')
 and p_check_out>p_check_in and p_adults>=1 and p_children>=0
 and p_adults<=coalesce(rt.max_adults,1) and p_children<=coalesce(rt.max_children,0)
 and p_adults+p_children<=coalesce(rt.max_guests,rt.max_adults+coalesce(rt.max_children,0),rt.max_adults,1)
 and avail.available_units>0
 and (p_destination is null or coalesce(p.destination,'') ilike '%'||p_destination||'%'
  or coalesce(p.city,'') ilike '%'||p_destination||'%' or coalesce(r.city,'') ilike '%'||p_destination||'%'
  or coalesce(p.address,'') ilike '%'||p_destination||'%' or coalesce(r.address,'') ilike '%'||p_destination||'%'
  or p.name ilike '%'||p_destination||'%')
 order by p.name,rt.name,rp.rate;
$$;

create or replace function public.anaira_marketplace_camp_search(
  p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0,p_destination text default null
) returns table(
  restaurant_id uuid,property_name text,destination text,city text,unit_type_id uuid,unit_name text,
  rate_plan_id uuid,rate_name text,pricing_mode text,rate numeric,available_units integer,
  max_guests integer,max_adults integer,max_children integer,cover_image_url text
) language sql security definer set search_path='' as $$
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
 and exists(select 1 from public.anaira_platform_stores s where s.restaurant_id=p.restaurant_id and s.store_type='hotel'
  and s.is_platform_store=false and s.enabled=true and s.published=true and s.marketplace_approval_status='approved')
 and (p_destination is null or p.destination ilike '%'||p_destination||'%' or p.city ilike '%'||p_destination||'%' or p.name ilike '%'||p_destination||'%')
 and (u.id is null or (p_adults>=1 and p_adults<=u.max_adults and p_children>=0 and p_children<=u.max_children and p_adults+p_children<=u.max_guests))
 order by p.name,u.name;
$$;

create or replace function public.anaira_marketplace_hms_hospitality_search(
  p_hospitality_type text,p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0,p_destination text default null
) returns table(
  restaurant_id uuid,property_name text,city text,address text,cover_image text,unit_type_id uuid,unit_name text,
  rate_plan_id uuid,rate_plan_name text,pricing_mode text,rate numeric,available_units integer,
  max_adults integer,max_children integer,max_guests integer
) language sql stable security definer set search_path='' as $$
 select r.id,r.name,r.city,r.address,coalesce(r.cover_image,hs.cover_image_url),rt.id,rt.name,rp.id,rp.name,
  coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit'),rp.rate,
  greatest(0,coalesce((select min(i.total_rooms-i.sold_rooms-i.blocked_rooms) from public.hms_inventory i
   where i.restaurant_id=r.id and i.room_type_id=rt.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),
   (select count(*) from public.hms_rooms rm where rm.restaurant_id=r.id and rm.room_type_id=rt.id and rm.active=true
    and lower(coalesce(rm.status,'')) not in ('maintenance','out_of_order'))::integer,0))::integer,
  rt.max_adults,rt.max_children,greatest(1,coalesce(rt.max_guests,coalesce(rt.max_adults,1)+coalesce(rt.max_children,0)))
 from public.restaurants r join public.hms_settings hs on hs.restaurant_id=r.id
 join public.hms_room_types rt on rt.restaurant_id=r.id and rt.active=true
 join lateral(select x.* from public.hms_rate_plans x where x.restaurant_id=r.id and x.room_type_id=rt.id and x.active=true
  and (x.active_from is null or x.active_from<=p_check_in) and (x.active_to is null or x.active_to>=p_check_out-1) order by x.rate asc limit 1) rp on true
 where coalesce(r.hospitality_type,hs.hospitality_type,'hotel')=p_hospitality_type and hs.hospitality_type=p_hospitality_type and r.status is distinct from 'inactive'
 and exists(select 1 from public.anaira_platform_stores s where s.restaurant_id=r.id and s.store_type='hotel'
  and s.is_platform_store=false and s.enabled=true and s.published=true and s.marketplace_approval_status='approved')
 and (p_destination is null or trim(p_destination)='' or lower(concat_ws(' ',r.name,r.city,r.address)) like '%'||lower(trim(p_destination))||'%')
 and p_adults>=1 and p_adults<=rt.max_adults and p_children>=0 and p_children<=rt.max_children
 and p_adults+p_children<=greatest(1,coalesce(rt.max_guests,coalesce(rt.max_adults,1)+coalesce(rt.max_children,0)))
 and greatest(0,coalesce((select min(i.total_rooms-i.sold_rooms-i.blocked_rooms) from public.hms_inventory i
   where i.restaurant_id=r.id and i.room_type_id=rt.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),
   (select count(*) from public.hms_rooms rm where rm.restaurant_id=r.id and rm.room_type_id=rt.id and rm.active=true
    and lower(coalesce(rm.status,'')) not in ('maintenance','out_of_order'))::integer,0))>0
 order by r.name,rt.name;
$$;

revoke all on function public.anaira_marketplace_hotel_search(date,date,integer,integer,text) from public;
revoke all on function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) from public;
revoke all on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) from public;
revoke all on function public.anaira_marketplace_hms_hospitality_search(text,date,date,integer,integer,text) from public;
grant execute on function public.anaira_marketplace_hotel_search(date,date,integer,integer,text) to anon,authenticated;
grant execute on function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) to anon,authenticated;
grant execute on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) to anon,authenticated;
grant execute on function public.anaira_marketplace_hms_hospitality_search(text,date,date,integer,integer,text) to anon,authenticated;
