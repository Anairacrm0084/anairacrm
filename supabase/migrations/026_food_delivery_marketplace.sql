-- Food delivery marketplace and rider operations.
create table if not exists public.delivery_orders (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 order_code text not null, customer_id uuid, customer_name text, customer_phone text, address jsonb not null default '{}'::jsonb,
 source text not null default 'anaira', status text not null default 'placed', payment_status text not null default 'pending',
 subtotal numeric(12,2) not null default 0, delivery_fee numeric(12,2) not null default 0, discount numeric(12,2) not null default 0, tax numeric(12,2) not null default 0, total_amount numeric(12,2) not null default 0,
 rider_id uuid, pos_order_id uuid, placed_at timestamptz not null default now(), accepted_at timestamptz, ready_at timestamptz, picked_up_at timestamptz, delivered_at timestamptz,
 metadata jsonb not null default '{}'::jsonb, unique(restaurant_id,order_code)
);
create table if not exists public.delivery_order_items (
 id uuid primary key default gen_random_uuid(), delivery_order_id uuid not null references public.delivery_orders(id) on delete cascade,
 menu_item_id uuid, name text not null, quantity integer not null default 1, unit_price numeric(12,2) not null default 0, modifiers jsonb not null default '{}'::jsonb
);
create table if not exists public.delivery_riders (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid references public.restaurants(id) on delete cascade,
 name text not null, phone text, status text not null default 'offline', vehicle_type text, current_location jsonb, active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.delivery_assignments (
 id uuid primary key default gen_random_uuid(), delivery_order_id uuid not null references public.delivery_orders(id) on delete cascade,
 rider_id uuid not null references public.delivery_riders(id), status text not null default 'assigned', assigned_at timestamptz not null default now(), accepted_at timestamptz, completed_at timestamptz
);
create index if not exists delivery_order_status_idx on public.delivery_orders(restaurant_id,status,placed_at);
