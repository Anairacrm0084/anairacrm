-- Global ANAIRA Hotels marketplace presentation layer.
-- Hotel PMS/booking data remains canonical in existing hotel/HMS tables.
create table if not exists public.anaira_hotel_store_banners (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.anaira_platform_stores(id) on delete cascade,
  title text not null,
  subtitle text,
  image_url text not null,
  mobile_image_url text,
  cta_label text,
  cta_url text,
  display_order integer not null default 0,
  active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists anaira_hotel_store_banners_public_idx on public.anaira_hotel_store_banners(store_id,active,display_order);
alter table public.anaira_hotel_store_banners enable row level security;
drop policy if exists anaira_hotel_store_banners_public on public.anaira_hotel_store_banners;
create policy anaira_hotel_store_banners_public on public.anaira_hotel_store_banners for select to anon,authenticated
using (active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at >= now()) and exists(select 1 from public.anaira_platform_stores s where s.id=store_id and s.store_type='hotel' and s.enabled=true and s.published=true));
drop policy if exists anaira_hotel_store_banners_admin on public.anaira_hotel_store_banners;
create policy anaira_hotel_store_banners_admin on public.anaira_hotel_store_banners for all to authenticated
using (public.anaira_current_is_super_admin())
with check (public.anaira_current_is_super_admin());
