-- Auto-generated restaurant storefronts. POS remains the operational catalog owner.
create table if not exists public.restaurant_storefronts (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 slug text not null, store_name text not null, status text not null default 'draft', published boolean not null default false,
 theme jsonb not null default '{}'::jsonb, seo jsonb not null default '{}'::jsonb, delivery_config jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(slug), unique(restaurant_id)
);
create table if not exists public.storefront_domains (
 id uuid primary key default gen_random_uuid(), storefront_id uuid not null references public.restaurant_storefronts(id) on delete cascade,
 domain text not null unique, domain_type text not null default 'subdomain', verified boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.storefront_sync_state (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 source_system text not null default 'anaira-pos', last_menu_sync_at timestamptz, last_inventory_sync_at timestamptz, last_order_sync_at timestamptz,
 status text not null default 'healthy', last_error text, metadata jsonb not null default '{}'::jsonb, unique(restaurant_id,source_system)
);
