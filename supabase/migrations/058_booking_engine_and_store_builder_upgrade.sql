-- ANAIRA Direct Booking Engine + multi-store builder upgrade
alter table public.restaurant_storefronts
  add column if not exists store_type text not null default 'restaurant',
  add column if not exists tagline text,
  add column if not exists logo_url text,
  add column if not exists cover_url text,
  add column if not exists currency text default 'INR',
  add column if not exists language text default 'en',
  add column if not exists contact jsonb not null default '{}'::jsonb,
  add column if not exists social jsonb not null default '{}'::jsonb,
  add column if not exists ordering_config jsonb not null default '{}'::jsonb;

alter table public.restaurant_storefronts drop constraint if exists restaurant_storefronts_restaurant_id_key;
create unique index if not exists restaurant_storefronts_restaurant_type_uq on public.restaurant_storefronts(restaurant_id, store_type);

alter table public.booking_reservations
  add column if not exists cancellation_reason text,
  add column if not exists special_requests text,
  add column if not exists promo_code text,
  add column if not exists payment_reference text,
  add column if not exists confirmation_sent_at timestamptz,
  add column if not exists source_detail text;

alter table public.booking_rate_plans
  add column if not exists min_stay integer default 1,
  add column if not exists max_stay integer,
  add column if not exists booking_window_days integer,
  add column if not exists active_from date,
  add column if not exists active_to date,
  add column if not exists extra_adult numeric(12,2) default 0,
  add column if not exists extra_child numeric(12,2) default 0;

alter table public.booking_addons
  add column if not exists description text,
  add column if not exists image_url text,
  add column if not exists taxable boolean not null default true;

create table if not exists public.booking_packages (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, code text, description text, price numeric(12,2) not null default 0, active boolean not null default true,
 start_date date, end_date date, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.booking_promotions (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 code text not null, name text not null, discount_type text not null default 'percent', discount_value numeric(12,2) not null default 0,
 min_nights integer default 1, start_date date, end_date date, active boolean not null default true, metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(restaurant_id,code)
);
create table if not exists public.booking_engine_settings (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade unique,
 template text not null default 'anaira-premium', locale text not null default 'en-IN', currency text not null default 'INR',
 multi_currency boolean not null default false, multi_language boolean not null default false, payment_mode text not null default 'pay_at_hotel',
 direct_booking_enabled boolean not null default true, packages_enabled boolean not null default true, addons_enabled boolean not null default true,
 promo_enabled boolean not null default true, guest_login_enabled boolean not null default false, terms_url text, privacy_url text,
 theme jsonb not null default '{}'::jsonb, policies jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table public.booking_packages enable row level security;
alter table public.booking_promotions enable row level security;
alter table public.booking_engine_settings enable row level security;
drop policy if exists booking_packages_tenant_access on public.booking_packages;
create policy booking_packages_tenant_access on public.booking_packages for all using ((restaurant_id = anaira_current_restaurant_id()) or anaira_current_is_super_admin()) with check ((restaurant_id = anaira_current_restaurant_id()) or anaira_current_is_super_admin());
drop policy if exists booking_promotions_tenant_access on public.booking_promotions;
create policy booking_promotions_tenant_access on public.booking_promotions for all using ((restaurant_id = anaira_current_restaurant_id()) or anaira_current_is_super_admin()) with check ((restaurant_id = anaira_current_restaurant_id()) or anaira_current_is_super_admin());
drop policy if exists booking_engine_settings_tenant_access on public.booking_engine_settings;
create policy booking_engine_settings_tenant_access on public.booking_engine_settings for all using ((restaurant_id = anaira_current_restaurant_id()) or anaira_current_is_super_admin()) with check ((restaurant_id = anaira_current_restaurant_id()) or anaira_current_is_super_admin());
create index if not exists booking_packages_lookup_idx on public.booking_packages(restaurant_id,start_date,end_date,active);
create index if not exists booking_promotions_lookup_idx on public.booking_promotions(restaurant_id,start_date,end_date,active);
