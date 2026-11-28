-- ANAIRA Hotel Marketplace settings: create the dedicated settings table
-- using the current platform-admin authorization helper.
create table if not exists public.anaira_platform_settings (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  value jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.anaira_platform_settings enable row level security;

grant select on public.anaira_platform_settings to anon, authenticated;
grant insert, update, delete on public.anaira_platform_settings to authenticated;

drop policy if exists anaira_platform_settings_public_hotel_read on public.anaira_platform_settings;
create policy anaira_platform_settings_public_hotel_read
on public.anaira_platform_settings
for select to anon, authenticated
using (key = any (array[
  'hotel_home_hero_image',
  'hotel_home_hero_mobile_image',
  'hotel_home_hero_media_type',
  'hotel_home_hero_mobile_media_type',
  'hotel_home_hero_video',
  'hotel_home_hero_mobile_video',
  'hotel_home_background_image',
  'hotel_home_background_mobile_image',
  'hotel_home_background_media_type',
  'hotel_home_background_mobile_media_type',
  'hotel_home_background_video',
  'hotel_home_background_mobile_video',
  'hotel_home_hero_overlay',
  'hotel_home_background_overlay',
  'hotel_home_hero_cta',
  'hotel_home_hero_cta_url',
  'hotel_home_primary_color',
  'hotel_home_accent_color',
  'hotel_home_background_color',
  'hotel_home_surface_color',
  'hotel_home_text_color',
  'hotel_home_featured_columns',
  'hotel_home_featured_card_height',
  'hotel_home_banner_height',
  'hotel_home_hero_min_height',
  'hotel_home_search_max_width',
  'hotel_home_section_spacing',
  'hotel_home_meta_title',
  'hotel_home_meta_description'
]));

drop policy if exists anaira_platform_settings_platform_admin_manage on public.anaira_platform_settings;
create policy anaira_platform_settings_platform_admin_manage
on public.anaira_platform_settings
for all to authenticated
using ((select private.is_platform_admin()))
with check ((select private.is_platform_admin()));

notify pgrst, 'reload schema';
