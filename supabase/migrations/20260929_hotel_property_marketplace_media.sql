-- Hotel marketplace background media controls
alter table public.hms_settings add column if not exists marketplace_background_media_type text not null default 'image';
alter table public.hms_settings add column if not exists marketplace_background_image_url text;
alter table public.hms_settings add column if not exists marketplace_background_video_url text;
alter table public.hms_settings add column if not exists marketplace_background_mobile_media_type text not null default 'image';
alter table public.hms_settings add column if not exists marketplace_background_mobile_image_url text;
alter table public.hms_settings add column if not exists marketplace_background_mobile_video_url text;
alter table public.hms_settings add column if not exists marketplace_background_overlay numeric not null default 0.48;

-- Restrict global hotel banner writes to Super Admin; public users remain read-only.
drop policy if exists hotel_store_banners_authenticated_manage on public.anaira_hotel_store_banners;
create policy hotel_store_banners_admin on public.anaira_hotel_store_banners
for all to authenticated
using (public.anaira_current_is_super_admin())
with check (public.anaira_current_is_super_admin());
