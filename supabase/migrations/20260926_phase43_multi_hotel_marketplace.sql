-- Phase 43: Multi-hotel marketplace foundation. All money remains server-derived.
create table if not exists public.anaira_marketplace_booking_financials(
 id uuid primary key default gen_random_uuid(), booking_id uuid not null unique references public.booking_reservations(id) on delete cascade,
 tenant_id uuid not null, gross_amount numeric not null default 0, commission_percent numeric not null default 0,
 commission_amount numeric not null default 0, gateway_fee numeric not null default 0, refund_amount numeric not null default 0,
 hotel_payable numeric not null default 0, anaira_revenue numeric not null default 0, currency text not null default 'INR',
 status text not null default 'pending', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.anaira_marketplace_booking_financials enable row level security;
drop policy if exists tenant_access on public.anaira_marketplace_booking_financials;
create policy tenant_access on public.anaira_marketplace_booking_financials for all to authenticated using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create table if not exists public.anaira_marketplace_settlements(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, period_start date not null, period_end date not null,
 gross_amount numeric not null default 0, commission_amount numeric not null default 0, gateway_fee numeric not null default 0,
 refunds numeric not null default 0, payable_amount numeric not null default 0, currency text not null default 'INR', status text not null default 'open',
 payout_reference text, paid_at timestamptz, created_at timestamptz not null default now(), unique(tenant_id,period_start,period_end));
alter table public.anaira_marketplace_settlements enable row level security;
drop policy if exists tenant_access on public.anaira_marketplace_settlements;
create policy tenant_access on public.anaira_marketplace_settlements for all to authenticated using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create index if not exists anaira_marketplace_financials_tenant_status_idx on public.anaira_marketplace_booking_financials(tenant_id,status,created_at desc);
create index if not exists anaira_marketplace_settlements_tenant_period_idx on public.anaira_marketplace_settlements(tenant_id,period_end desc);
create or replace function public.anaira_marketplace_hotel_search(p_check_in date,p_check_out date,p_adults integer default 2,p_children integer default 0,p_destination text default null)
returns table(restaurant_id uuid,hotel_name text,city text,address text,logo text,cover_image text,listing_override jsonb,available_room_types bigint)
language sql stable security definer set search_path=public,pg_temp as $$
 select r.id,r.name,r.city,r.address,r.logo,r.cover_image,coalesce(m.listing_override,'{}'::jsonb),
 count(distinct i.room_type_id) filter(where i.closed=false and i.total_rooms-coalesce(i.held_rooms,0)-coalesce(i.booked_rooms,0)>0)
 from public.anaira_store_memberships m join public.anaira_platform_stores s on s.id=m.store_id and s.store_type='hotel' and s.enabled=true and s.published=true
 join public.restaurants r on r.id=m.restaurant_id left join public.booking_inventory i on i.restaurant_id=r.id and i.stay_date>=p_check_in and i.stay_date<p_check_out
 where m.enabled=true and (p_destination is null or trim(p_destination)='' or lower(concat_ws(' ',r.name,r.city,r.address)) like '%'||lower(trim(p_destination))||'%')
 group by r.id,r.name,r.city,r.address,r.logo,r.cover_image,m.listing_override,m.sort_order order by m.sort_order,r.name;
$$;
grant execute on function public.anaira_marketplace_hotel_search(date,date,integer,integer,text) to anon,authenticated;
