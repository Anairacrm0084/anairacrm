-- ANAIRA Hotel Marketplace: canonical destination assignment for hotel listings.
-- Destination cards are platform-owned; each hotel may be assigned to one destination
-- from Hotel Property Setup. Marketplace search uses that assignment when a configured
-- destination is selected, while free-text search keeps legacy city/address behavior.

alter table public.hms_settings
  add column if not exists marketplace_destination_id uuid
  references public.anaira_hotel_store_destinations(id) on delete set null;

create index if not exists hms_settings_marketplace_destination_idx
  on public.hms_settings(marketplace_destination_id);

create or replace function public.anaira_marketplace_hotel_search(
 p_check_in date,
 p_check_out date,
 p_adults integer default 2,
 p_children integer default 0,
 p_destination text default null,
 p_min_price numeric default null,
 p_max_price numeric default null,
 p_min_rating numeric default null,
 p_sort text default 'recommended'
)
returns table(
 restaurant_id uuid,hotel_name text,city text,address text,logo text,cover_image text,listing_override jsonb,
 available_room_types bigint,min_rate numeric,star_rating numeric,review_count integer,listing_rating numeric,
 featured boolean,ranking_score numeric,latitude numeric,longitude numeric
)
language sql stable security definer set search_path=public,pg_temp as $$
 with requested_destination as (
   select exists(
     select 1
     from public.anaira_hotel_store_destinations d
     join public.anaira_platform_stores ps on ps.id=d.store_id
     where d.active=true and ps.store_type='hotel' and ps.enabled=true and ps.published=true
       and lower(trim(d.name))=lower(trim(p_destination))
   ) as is_configured
 ),
 base as (
  select r.id,r.name,r.city,r.address,r.logo,r.cover_image,
    coalesce((
      select sm.listing_override
      from public.anaira_store_memberships sm
      join public.anaira_platform_stores ps on ps.id=sm.store_id and ps.store_type='hotel'
      where sm.restaurant_id=r.id and sm.enabled=true
      limit 1
    ),'{}'::jsonb) as listing_override,
    coalesce(l.rating,0)::numeric as listing_rating,
    coalesce(l.review_count,0)::int as review_count,
    coalesce(l.featured,false) as featured,
    coalesce(l.ranking_score,0)::numeric as ranking_score,
    hs.star_rating,hs.latitude,hs.longitude,
    count(distinct i.room_type_id) filter(
      where i.closed=false
        and i.total_rooms-coalesce(i.sold_rooms,0)-coalesce(i.blocked_rooms,0)>0
    ) as available_room_types,
    min(rp.rate) filter(where rp.active=true and rp.room_type_id=i.room_type_id) as min_rate
  from public.anaira_marketplace_listings l
  join public.restaurants r on r.id=l.restaurant_id
  left join public.hms_settings hs on hs.restaurant_id=r.id
  left join public.anaira_hotel_store_destinations dest
    on dest.id=hs.marketplace_destination_id and dest.active=true
  left join public.hms_inventory i
    on i.restaurant_id=r.id and i.stay_date>=p_check_in and i.stay_date<p_check_out
  left join public.hms_rate_plans rp
    on rp.restaurant_id=r.id and rp.active=true
  where l.marketplace_visible=true
    and l.approval_status='approved'
    and l.hotel_booking_enabled=true
    and (
      p_destination is null or trim(p_destination)=''
      or (
        (select is_configured from requested_destination)
        and lower(coalesce(dest.name,''))=lower(trim(p_destination))
      )
      or (
        not (select is_configured from requested_destination)
        and lower(concat_ws(' ',r.name,r.city,r.address)) like '%'||lower(trim(p_destination))||'%'
      )
    )
  group by r.id,r.name,r.city,r.address,r.logo,r.cover_image,l.rating,l.review_count,
    l.featured,l.ranking_score,hs.star_rating,hs.latitude,hs.longitude
 )
 select * from base
 where available_room_types>0
   and (p_min_price is null or min_rate>=p_min_price)
   and (p_max_price is null or min_rate<=p_max_price)
   and (p_min_rating is null or greatest(coalesce(listing_rating,0),coalesce(star_rating,0))>=p_min_rating)
 order by
   case when p_sort='price_asc' then min_rate end asc nulls last,
   case when p_sort='price_desc' then min_rate end desc nulls last,
   case when p_sort='rating' then listing_rating end desc nulls last,
   case when p_sort='distance' then hotel_name end asc,
   featured desc,ranking_score desc,listing_rating desc,hotel_name asc;
$$;

grant execute on function public.anaira_marketplace_hotel_search(
 date,date,integer,integer,text,numeric,numeric,numeric,text
) to anon,authenticated;
