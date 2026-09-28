-- Global hotel marketplace destination cards owned by Super Admin.
create table if not exists public.anaira_hotel_store_destinations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.anaira_platform_stores(id) on delete cascade,
  name text not null,
  subtitle text,
  image_url text not null,
  mobile_image_url text,
  cta_label text default 'Explore hotels',
  cta_url text,
  display_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists anaira_hotel_store_destinations_public_idx
  on public.anaira_hotel_store_destinations(store_id, active, display_order);

alter table public.anaira_hotel_store_destinations enable row level security;

drop policy if exists anaira_hotel_store_destinations_public on public.anaira_hotel_store_destinations;
create policy anaira_hotel_store_destinations_public
  on public.anaira_hotel_store_destinations
  for select to anon, authenticated
  using (
    active and exists (
      select 1 from public.anaira_platform_stores s
      where s.id=store_id and s.store_type='hotel' and s.enabled=true and s.published=true
    )
  );

drop policy if exists anaira_hotel_store_destinations_admin on public.anaira_hotel_store_destinations;
create policy anaira_hotel_store_destinations_admin
  on public.anaira_hotel_store_destinations
  for all to authenticated
  using (public.anaira_current_is_super_admin())
  with check (public.anaira_current_is_super_admin());
