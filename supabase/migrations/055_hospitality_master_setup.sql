-- ANAIRA hospitality master setup expansion.
-- Adds real property, hotel, room, rate, inventory and restaurant setup fields.

alter table public.restaurants
  add column if not exists legal_name text,
  add column if not exists whatsapp text,
  add column if not exists website text,
  add column if not exists city text,
  add column if not exists state text,
  add column if not exists country text default 'India',
  add column if not exists postal_code text,
  add column if not exists landmark text,
  add column if not exists latitude numeric(10,7),
  add column if not exists longitude numeric(10,7),
  add column if not exists business_type text default 'hotel_restaurant',
  add column if not exists opening_time time,
  add column if not exists closing_time time,
  add column if not exists weekly_off text,
  add column if not exists dine_in_enabled boolean not null default true,
  add column if not exists pickup_enabled boolean not null default true,
  add column if not exists reservation_enabled boolean not null default false,
  add column if not exists food_ordering_enabled boolean not null default false,
  add column if not exists marketplace_visible boolean not null default false,
  add column if not exists gallery jsonb not null default '[]'::jsonb;

alter table public.hms_settings
  add column if not exists short_name text,
  add column if not exists legal_name text,
  add column if not exists description text,
  add column if not exists phone text,
  add column if not exists whatsapp text,
  add column if not exists email text,
  add column if not exists website text,
  add column if not exists address text,
  add column if not exists city text,
  add column if not exists state text,
  add column if not exists country text default 'India',
  add column if not exists postal_code text,
  add column if not exists landmark text,
  add column if not exists latitude numeric(10,7),
  add column if not exists longitude numeric(10,7),
  add column if not exists star_rating numeric(2,1),
  add column if not exists early_checkin_policy text,
  add column if not exists late_checkout_policy text,
  add column if not exists cancellation_policy text,
  add column if not exists child_policy text,
  add column if not exists pet_policy text,
  add column if not exists smoking_policy text,
  add column if not exists tax_percent numeric(6,2) default 0,
  add column if not exists logo_url text,
  add column if not exists cover_image_url text,
  add column if not exists gallery jsonb not null default '[]'::jsonb;

alter table public.hms_room_types
  add column if not exists short_description text,
  add column if not exists bed_type text,
  add column if not exists number_of_beds integer default 1,
  add column if not exists extra_adult_price numeric(12,2) default 0,
  add column if not exists extra_child_price numeric(12,2) default 0,
  add column if not exists weekend_price numeric(12,2) default 0,
  add column if not exists tax_percent numeric(6,2) default 0,
  add column if not exists amenities jsonb not null default '[]'::jsonb,
  add column if not exists image_urls jsonb not null default '[]'::jsonb;

alter table public.hms_rooms
  add column if not exists building text,
  add column if not exists room_view text,
  add column if not exists notes text;

alter table public.hms_rate_plans
  add column if not exists description text,
  add column if not exists room_type_id uuid references public.hms_room_types(id) on delete cascade,
  add column if not exists rate numeric(12,2) default 0,
  add column if not exists occupancy integer default 2,
  add column if not exists extra_adult numeric(12,2) default 0,
  add column if not exists extra_child numeric(12,2) default 0,
  add column if not exists min_stay integer default 1,
  add column if not exists max_stay integer,
  add column if not exists booking_window_days integer,
  add column if not exists active_from date,
  add column if not exists active_to date;

create index if not exists hms_rate_plans_room_type_idx on public.hms_rate_plans(restaurant_id, room_type_id);
create index if not exists hms_inventory_room_date_idx on public.hms_inventory(restaurant_id, room_type_id, stay_date);
