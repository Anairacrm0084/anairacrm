-- Hotel Booking Engine: independent from CRM/PMS implementation, linked through IDs/events.
create table if not exists public.booking_room_types (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, code text, description text, max_occupancy integer not null default 2, base_rate numeric(12,2) not null default 0,
 active boolean not null default true, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.booking_rate_plans (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_type_id uuid references public.booking_room_types(id) on delete cascade, name text not null, code text, board_type text not null default 'room_only',
 cancellation_policy text, rate numeric(12,2) not null default 0, active boolean not null default true, restrictions jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.booking_inventory (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_type_id uuid not null references public.booking_room_types(id) on delete cascade, stay_date date not null, total_rooms integer not null default 0,
 held_rooms integer not null default 0, booked_rooms integer not null default 0, closed boolean not null default false, created_at timestamptz not null default now(),
 unique(restaurant_id,room_type_id,stay_date)
);
create table if not exists public.booking_reservations (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 booking_code text not null, customer_id uuid, room_type_id uuid references public.booking_room_types(id), rate_plan_id uuid references public.booking_rate_plans(id),
 check_in date not null, check_out date not null, adults integer not null default 2, children integer not null default 0,
 guest_name text not null, guest_email text, guest_phone text, status text not null default 'pending', payment_status text not null default 'unpaid',
 subtotal numeric(12,2) not null default 0, tax_amount numeric(12,2) not null default 0, total_amount numeric(12,2) not null default 0,
 source text not null default 'direct', metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(restaurant_id,booking_code)
);
create table if not exists public.booking_addons (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, addon_type text not null default 'service', price numeric(12,2) not null default 0, active boolean not null default true, metadata jsonb not null default '{}'::jsonb
);
create table if not exists public.booking_reservation_addons (
 id uuid primary key default gen_random_uuid(), reservation_id uuid not null references public.booking_reservations(id) on delete cascade,
 addon_id uuid not null references public.booking_addons(id), quantity integer not null default 1, unit_price numeric(12,2) not null default 0
);
create index if not exists booking_inventory_lookup_idx on public.booking_inventory(restaurant_id,stay_date,room_type_id);
create index if not exists booking_reservations_dates_idx on public.booking_reservations(restaurant_id,check_in,check_out,status);
