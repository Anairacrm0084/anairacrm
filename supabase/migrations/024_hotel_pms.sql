-- Hotel PMS: operational ownership for rooms, stays and housekeeping.
create table if not exists public.pms_rooms (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_number text not null, room_type text, floor text, status text not null default 'available', housekeeping_status text not null default 'clean',
 guest_name text, reservation_id uuid, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(restaurant_id,room_number)
);
create table if not exists public.pms_reservations (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 booking_code text, guest_name text not null, guest_phone text, room_id uuid references public.pms_rooms(id), check_in date not null, check_out date not null,
 status text not null default 'reserved', source text, total_amount numeric(12,2) not null default 0, metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.pms_housekeeping_tasks (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_id uuid not null references public.pms_rooms(id) on delete cascade, task_type text not null default 'cleaning', status text not null default 'pending',
 assigned_to uuid, priority text not null default 'normal', notes text, created_at timestamptz not null default now(), completed_at timestamptz
);
create index if not exists pms_room_status_idx on public.pms_rooms(restaurant_id,status,housekeeping_status);
create index if not exists pms_reservation_dates_idx on public.pms_reservations(restaurant_id,check_in,check_out,status);
