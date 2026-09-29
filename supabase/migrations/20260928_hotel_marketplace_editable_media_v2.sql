-- Hotel Marketplace editable media contract.
-- Presentation media only; hotel/PMS operational data remains canonical elsewhere.
alter table if exists public.anaira_hotel_store_banners
  add column if not exists media_type text not null default 'image',
  add column if not exists mobile_media_type text not null default 'image',
  add column if not exists video_url text,
  add column if not exists mobile_video_url text,
  add column if not exists cta_url text,
  add column if not exists active boolean not null default true,
  add column if not exists display_order integer not null default 0;

create index if not exists anaira_hotel_store_banners_media_order_idx
  on public.anaira_hotel_store_banners(store_id, active, display_order);

alter table if exists public.anaira_hotel_store_destinations
  add column if not exists mobile_image_url text,
  add column if not exists cta_label text default 'Explore hotels',
  add column if not exists cta_url text,
  add column if not exists display_order integer not null default 0,
  add column if not exists active boolean not null default true;

create index if not exists anaira_hotel_store_destinations_media_order_idx
  on public.anaira_hotel_store_destinations(store_id, active, display_order);
