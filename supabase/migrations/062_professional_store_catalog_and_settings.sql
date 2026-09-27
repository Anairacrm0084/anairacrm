-- ANAIRA Professional Store Builder / Zomato-style catalog foundation
-- Applies to the existing two platform stores. Does not duplicate POS/HMS operational tables.

alter table public.anaira_marketplace_menu_items
  add column if not exists category_id uuid,
  add column if not exists image_url text,
  add column if not exists discount_price numeric,
  add column if not exists veg_type text not null default 'veg',
  add column if not exists tags jsonb not null default '[]'::jsonb,
  add column if not exists prep_time_minutes integer,
  add column if not exists tax_percent numeric not null default 0,
  add column if not exists featured boolean not null default false,
  add column if not exists display_order integer not null default 0,
  add column if not exists available_days integer[] not null default '{0,1,2,3,4,5,6}',
  add column if not exists available_from time,
  add column if not exists available_to time,
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.anaira_store_categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  store_id uuid references public.anaira_platform_stores(id) on delete cascade,
  name text not null,
  description text,
  image_url text,
  display_order integer not null default 0,
  active boolean not null default true,
  available_days integer[] not null default '{0,1,2,3,4,5,6}',
  available_from time,
  available_to time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists anaira_store_categories_unique_name
  on public.anaira_store_categories(restaurant_id, lower(name));
create index if not exists anaira_store_categories_order_idx
  on public.anaira_store_categories(restaurant_id, active, display_order);

create table if not exists public.anaira_store_item_variants (
  id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.anaira_marketplace_menu_items(id) on delete cascade,
  name text not null,
  price numeric not null default 0,
  display_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists anaira_store_item_variants_item_idx
  on public.anaira_store_item_variants(menu_item_id, active, display_order);

create table if not exists public.anaira_store_item_addons (
  id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.anaira_marketplace_menu_items(id) on delete cascade,
  name text not null,
  price numeric not null default 0,
  display_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists anaira_store_item_addons_item_idx
  on public.anaira_store_item_addons(menu_item_id, active, display_order);

create table if not exists public.anaira_store_settings (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  store_id uuid not null references public.anaira_platform_stores(id) on delete cascade,
  store_type text not null check (store_type in ('hotel','restaurant')),
  slug text,
  seo_title text,
  seo_description text,
  min_order_amount numeric not null default 0,
  delivery_fee numeric not null default 0,
  delivery_radius_km numeric,
  tax_percent numeric not null default 0,
  timings jsonb not null default '{}'::jsonb,
  delivery_zones jsonb not null default '[]'::jsonb,
  payment_methods jsonb not null default '["pay_at_hotel","cod"]'::jsonb,
  social_links jsonb not null default '{}'::jsonb,
  policy_text jsonb not null default '{}'::jsonb,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id, restaurant_id)
);
create unique index if not exists anaira_store_settings_slug_unique
  on public.anaira_store_settings(slug) where slug is not null;

create table if not exists public.anaira_store_offers (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  store_id uuid not null references public.anaira_platform_stores(id) on delete cascade,
  code text not null,
  title text not null,
  description text,
  discount_type text not null default 'percent' check (discount_type in ('percent','flat')),
  discount_value numeric not null default 0,
  min_order_amount numeric not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  usage_limit integer,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id, restaurant_id, code)
);

alter table public.anaira_store_categories enable row level security;
alter table public.anaira_store_item_variants enable row level security;
alter table public.anaira_store_item_addons enable row level security;
alter table public.anaira_store_settings enable row level security;
alter table public.anaira_store_offers enable row level security;

create or replace function public.anaira_public_restaurant_store_enabled(p_restaurant_id uuid) returns boolean
language sql security definer set search_path=public as $$
  select exists(
    select 1 from public.anaira_store_memberships m
    join public.anaira_platform_stores s on s.id=m.store_id
    where m.restaurant_id=p_restaurant_id and m.enabled=true and s.store_type='restaurant' and s.enabled=true and s.published=true
  );
$$;
grant execute on function public.anaira_public_restaurant_store_enabled(uuid) to anon,authenticated;

-- Tenant writes; published store data is publicly readable for the customer-facing store.
drop policy if exists anaira_store_categories_tenant on public.anaira_store_categories;
create policy anaira_store_categories_tenant on public.anaira_store_categories for all to authenticated
using (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id())
with check (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id());
drop policy if exists anaira_store_categories_public on public.anaira_store_categories;
create policy anaira_store_categories_public on public.anaira_store_categories for select to anon,authenticated
using (active and exists (select 1 from public.anaira_platform_stores s where s.id = store_id and s.enabled and s.published));

drop policy if exists anaira_store_item_variants_tenant on public.anaira_store_item_variants;
create policy anaira_store_item_variants_tenant on public.anaira_store_item_variants for all to authenticated
using (anaira_current_is_super_admin() or exists (select 1 from public.anaira_marketplace_menu_items mi where mi.id = menu_item_id and mi.restaurant_id = anaira_current_restaurant_id()))
with check (anaira_current_is_super_admin() or exists (select 1 from public.anaira_marketplace_menu_items mi where mi.id = menu_item_id and mi.restaurant_id = anaira_current_restaurant_id()));
drop policy if exists anaira_store_item_variants_public on public.anaira_store_item_variants;
create policy anaira_store_item_variants_public on public.anaira_store_item_variants for select to anon,authenticated
using (active and exists (select 1 from public.anaira_marketplace_menu_items mi where mi.id=menu_item_id and public.anaira_public_restaurant_store_enabled(mi.restaurant_id)));

drop policy if exists anaira_store_item_addons_tenant on public.anaira_store_item_addons;
create policy anaira_store_item_addons_tenant on public.anaira_store_item_addons for all to authenticated
using (anaira_current_is_super_admin() or exists (select 1 from public.anaira_marketplace_menu_items mi where mi.id = menu_item_id and mi.restaurant_id = anaira_current_restaurant_id()))
with check (anaira_current_is_super_admin() or exists (select 1 from public.anaira_marketplace_menu_items mi where mi.id = menu_item_id and mi.restaurant_id = anaira_current_restaurant_id()));
drop policy if exists anaira_store_item_addons_public on public.anaira_store_item_addons;
create policy anaira_store_item_addons_public on public.anaira_store_item_addons for select to anon,authenticated
using (active and exists (select 1 from public.anaira_marketplace_menu_items mi where mi.id=menu_item_id and public.anaira_public_restaurant_store_enabled(mi.restaurant_id)));

drop policy if exists anaira_store_settings_tenant on public.anaira_store_settings;
create policy anaira_store_settings_tenant on public.anaira_store_settings for all to authenticated
using (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id())
with check (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id());
drop policy if exists anaira_store_settings_public on public.anaira_store_settings;
create policy anaira_store_settings_public on public.anaira_store_settings for select to anon,authenticated
using (published and exists (select 1 from public.anaira_platform_stores s where s.id=store_id and s.enabled and s.published));

drop policy if exists anaira_store_offers_tenant on public.anaira_store_offers;
create policy anaira_store_offers_tenant on public.anaira_store_offers for all to authenticated
using (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id())
with check (anaira_current_is_super_admin() or restaurant_id = anaira_current_restaurant_id());
drop policy if exists anaira_store_offers_public on public.anaira_store_offers;
create policy anaira_store_offers_public on public.anaira_store_offers for select to anon,authenticated
using (active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at >= now()) and exists (select 1 from public.anaira_platform_stores s where s.id=store_id and s.enabled and s.published));

create index if not exists anaira_store_offers_public_idx on public.anaira_store_offers(store_id, active, starts_at, ends_at);
do $$ begin
  if not exists (select 1 from pg_constraint where conname='anaira_marketplace_menu_items_category_id_fkey') then
    alter table public.anaira_marketplace_menu_items add constraint anaira_marketplace_menu_items_category_id_fkey foreign key (category_id) references public.anaira_store_categories(id) on delete set null;
  end if;
end $$;

create index if not exists anaira_store_menu_display_idx on public.anaira_marketplace_menu_items(restaurant_id, active, display_order, category_name);

-- Seed one settings row per existing platform membership so the builder can open immediately.
insert into public.anaira_store_settings(restaurant_id,store_id,store_type,published)
select m.restaurant_id,m.store_id,s.store_type,s.published
from public.anaira_store_memberships m
join public.anaira_platform_stores s on s.id=m.store_id
on conflict (store_id,restaurant_id) do nothing;
