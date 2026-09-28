-- Restaurant Marketplace PRO home/presentation layer.
-- Does NOT become the operational menu/order master. Restaurant SaaS remains canonical.
create table if not exists public.anaira_store_banners (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.anaira_platform_stores(id) on delete cascade,
  restaurant_id uuid references public.restaurants(id) on delete cascade,
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
create index if not exists anaira_store_banners_public_idx on public.anaira_store_banners(store_id,active,display_order);
create index if not exists anaira_store_banners_restaurant_idx on public.anaira_store_banners(restaurant_id,active,display_order);

create table if not exists public.anaira_marketplace_featured_items (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.anaira_platform_stores(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  external_item_id text not null,
  title_override text,
  image_override text,
  badge text,
  display_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id,restaurant_id,external_item_id)
);
create index if not exists anaira_marketplace_featured_items_public_idx on public.anaira_marketplace_featured_items(store_id,active,display_order);

alter table public.anaira_store_banners enable row level security;
alter table public.anaira_marketplace_featured_items enable row level security;

drop policy if exists anaira_store_banners_public on public.anaira_store_banners;
create policy anaira_store_banners_public on public.anaira_store_banners for select to anon,authenticated
using (active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at >= now()) and exists(select 1 from public.anaira_platform_stores s where s.id=store_id and s.store_type='restaurant' and s.enabled=true and s.published=true));
drop policy if exists anaira_store_banners_admin on public.anaira_store_banners;
create policy anaira_store_banners_admin on public.anaira_store_banners for all to authenticated
using (anaira_current_is_super_admin() or (restaurant_id = anaira_current_restaurant_id()))
with check (anaira_current_is_super_admin() or (restaurant_id = anaira_current_restaurant_id()));

drop policy if exists anaira_featured_items_public on public.anaira_marketplace_featured_items;
create policy anaira_featured_items_public on public.anaira_marketplace_featured_items for select to anon,authenticated
using (active and exists(select 1 from public.anaira_platform_stores s where s.id=store_id and s.store_type='restaurant' and s.enabled=true and s.published=true));
drop policy if exists anaira_featured_items_admin on public.anaira_marketplace_featured_items;
create policy anaira_featured_items_admin on public.anaira_marketplace_featured_items for all to authenticated
using (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id())
with check (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id());
