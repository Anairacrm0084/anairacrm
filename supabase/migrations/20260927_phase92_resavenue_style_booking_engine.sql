-- Phase 92: ResAvenue-style direct booking / marketplace extension.
-- Existing HMS, booking, PMS and CRM records remain the source of truth.
-- This migration only adds marketplace/ranking metadata and search helpers.

alter table public.anaira_marketplace_listings
  add column if not exists rating numeric(3,2) not null default 0,
  add column if not exists review_count integer not null default 0,
  add column if not exists featured boolean not null default false,
  add column if not exists ranking_score numeric(12,4) not null default 0,
  add column if not exists commission_percent numeric(6,3) not null default 0,
  add column if not exists booking_engine_template text not null default 'anaira-premium',
  add column if not exists seo_slug text;

create index if not exists anaira_marketplace_listings_ranking_idx
  on public.anaira_marketplace_listings(marketplace_visible,approval_status,hotel_booking_enabled,featured,ranking_score desc);

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
 with base as (
  select r.id,r.name,r.city,r.address,r.logo,r.cover_image,
    coalesce((select sm.listing_override from public.anaira_store_memberships sm join public.anaira_platform_stores ps on ps.id=sm.store_id and ps.store_type='hotel' where sm.restaurant_id=r.id and sm.enabled=true limit 1),'{}'::jsonb) as listing_override,
    coalesce(l.rating,0)::numeric as listing_rating,coalesce(l.review_count,0)::int as review_count,
    coalesce(l.featured,false) as featured,coalesce(l.ranking_score,0)::numeric as ranking_score,
    hs.star_rating,hs.latitude,hs.longitude,
    count(distinct i.room_type_id) filter(where i.closed=false and i.total_rooms-coalesce(i.sold_rooms,0)-coalesce(i.blocked_rooms,0)>0) as available_room_types,
    min(rp.rate) filter(where rp.active=true and rp.room_type_id=i.room_type_id) as min_rate
  from public.anaira_marketplace_listings l
  join public.restaurants r on r.id=l.restaurant_id
  left join public.hms_settings hs on hs.restaurant_id=r.id
  left join public.hms_inventory i on i.restaurant_id=r.id and i.stay_date>=p_check_in and i.stay_date<p_check_out
  left join public.hms_rate_plans rp on rp.restaurant_id=r.id and rp.active=true
  where l.marketplace_visible=true and l.approval_status='approved' and l.hotel_booking_enabled=true
    and (p_destination is null or trim(p_destination)='' or lower(concat_ws(' ',r.name,r.city,r.address)) like '%'||lower(trim(p_destination))||'%')
  group by r.id,r.name,r.city,r.address,r.logo,r.cover_image,l.rating,l.review_count,l.featured,l.ranking_score,hs.star_rating,hs.latitude,hs.longitude
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

grant execute on function public.anaira_marketplace_hotel_search(date,date,integer,integer,text,numeric,numeric,numeric,text) to anon,authenticated;

create table if not exists public.booking_rate_rules(
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null,
 rule_type text not null default 'seasonal' check(rule_type in ('seasonal','weekend','occupancy','booking_window','length_of_stay','last_minute','manual')),
 adjustment_type text not null default 'percent' check(adjustment_type in ('percent','fixed')),
 adjustment_value numeric(12,2) not null default 0,
 min_occupancy numeric(5,2), max_occupancy numeric(5,2),
 min_days_before integer, max_days_before integer,
 min_nights integer, max_nights integer,
 start_date date, end_date date,
 active boolean not null default true,
 priority integer not null default 100,
 metadata jsonb not null default '{}',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.booking_rate_rules enable row level security;
drop policy if exists booking_rate_rules_tenant on public.booking_rate_rules;
create policy booking_rate_rules_tenant on public.booking_rate_rules for all to authenticated
using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create index if not exists booking_rate_rules_lookup on public.booking_rate_rules(restaurant_id,active,priority,start_date,end_date);

create table if not exists public.booking_channel_allocations(
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_type_id uuid references public.hms_room_types(id) on delete cascade,
 channel_code text not null,
 allocation integer not null default 0,
 active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(restaurant_id,room_type_id,channel_code)
);
alter table public.booking_channel_allocations enable row level security;
drop policy if exists booking_channel_allocations_tenant on public.booking_channel_allocations;
create policy booking_channel_allocations_tenant on public.booking_channel_allocations for all to authenticated
using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
