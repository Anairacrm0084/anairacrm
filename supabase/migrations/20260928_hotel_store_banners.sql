create table if not exists public.anaira_hotel_store_banners (
 id uuid primary key default gen_random_uuid(), store_id uuid not null, title text, subtitle text, image_url text, mobile_image_url text, cta_label text, cta_url text, display_order integer not null default 0, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists anaira_hotel_store_banners_public_idx on public.anaira_hotel_store_banners(store_id, active, display_order);
alter table public.anaira_hotel_store_banners enable row level security;
