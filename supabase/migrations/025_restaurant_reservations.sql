-- Restaurant reservation engine independent from POS billing.
create table if not exists public.restaurant_reservation_tables (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 table_number text not null, capacity integer not null default 2, section text, active boolean not null default true, metadata jsonb not null default '{}'::jsonb,
 unique(restaurant_id,table_number)
);
create table if not exists public.restaurant_reservations (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 reservation_code text not null, customer_id uuid, guest_name text not null, guest_phone text, guest_email text,
 reservation_date date not null, reservation_time time not null, party_size integer not null default 2, duration_minutes integer not null default 90,
 status text not null default 'confirmed', source text not null default 'direct', table_id uuid references public.restaurant_reservation_tables(id), special_request text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(restaurant_id,reservation_code)
);
create table if not exists public.restaurant_waitlist (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 guest_name text not null, guest_phone text, party_size integer not null default 2, requested_date date not null, requested_time time, status text not null default 'waiting',
 created_at timestamptz not null default now()
);
create index if not exists restaurant_reservations_slot_idx on public.restaurant_reservations(restaurant_id,reservation_date,reservation_time,status);
