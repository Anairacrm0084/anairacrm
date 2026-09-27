-- ANAIRA UNIFIED HOSPITALITY + FOOD MARKETPLACE
-- Super Admin / Business Admin / Customer Marketplace contracts.
-- Operational engines remain owners: Booking Engine->PMS, Food Marketplace->POS, CRM->Customer 360.

create table if not exists public.anaira_marketplace_businesses (
  id uuid primary key default gen_random_uuid(),
  business_type text not null check (business_type in ('hotel','restaurant','hotel_restaurant')),
  business_name text not null,
  slug text not null unique,
  city text,
  address text,
  owner_user_id uuid references auth.users(id) on delete set null,
  is_approved boolean not null default false,
  is_active boolean not null default true,
  marketplace_visible boolean not null default false,
  hotel_booking_enabled boolean not null default false,
  food_ordering_enabled boolean not null default false,
  restaurant_reservation_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.anaira_hotel_properties (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.anaira_marketplace_businesses(id) on delete cascade,
  name text not null,
  description text,
  check_in_time time,
  check_out_time time,
  currency text not null default 'INR',
  tax_percent numeric(6,2) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.anaira_hotel_room_types (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.anaira_hotel_properties(id) on delete cascade,
  name text not null,
  description text,
  base_price numeric(12,2) not null default 0,
  max_guests integer not null default 2,
  total_rooms integer not null default 1,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.anaira_hotel_inventory (
  id uuid primary key default gen_random_uuid(),
  room_type_id uuid not null references public.anaira_hotel_room_types(id) on delete cascade,
  inventory_date date not null,
  available_rooms integer not null default 0,
  price numeric(12,2),
  closed boolean not null default false,
  unique(room_type_id, inventory_date)
);

create table if not exists public.anaira_marketplace_restaurants (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.anaira_marketplace_businesses(id) on delete cascade,
  cuisine text,
  rating numeric(3,2) default 0,
  delivery_enabled boolean not null default true,
  pickup_enabled boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.anaira_marketplace_menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.anaira_marketplace_restaurants(id) on delete cascade,
  category_name text,
  item_name text not null,
  description text,
  price numeric(12,2) not null default 0,
  is_veg boolean,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.anaira_marketplace_bookings (
  id uuid primary key default gen_random_uuid(),
  booking_code text not null unique,
  customer_user_id uuid references auth.users(id) on delete set null,
  business_id uuid not null references public.anaira_marketplace_businesses(id),
  property_id uuid not null references public.anaira_hotel_properties(id),
  room_type_id uuid not null references public.anaira_hotel_room_types(id),
  check_in date not null,
  check_out date not null,
  guests integer not null default 1,
  rooms integer not null default 1,
  status text not null default 'pending' check (status in ('pending','confirmed','cancelled','checked_in','checked_out','no_show')),
  subtotal numeric(12,2) not null default 0,
  tax numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  pms_reservation_id uuid,
  crm_customer_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.anaira_marketplace_orders (
  id uuid primary key default gen_random_uuid(),
  order_code text not null unique,
  customer_user_id uuid references auth.users(id) on delete set null,
  business_id uuid not null references public.anaira_marketplace_businesses(id),
  restaurant_id uuid not null references public.anaira_marketplace_restaurants(id),
  order_type text not null default 'delivery' check (order_type in ('delivery','pickup','dine_in')),
  status text not null default 'pending' check (status in ('pending','accepted','preparing','ready','out_for_delivery','delivered','cancelled')),
  subtotal numeric(12,2) not null default 0,
  delivery_fee numeric(12,2) not null default 0,
  tax numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  pos_order_id uuid,
  crm_customer_id uuid,
  delivery_address jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.anaira_marketplace_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.anaira_marketplace_orders(id) on delete cascade,
  menu_item_id uuid references public.anaira_marketplace_menu_items(id) on delete set null,
  item_name text not null,
  quantity integer not null default 1,
  unit_price numeric(12,2) not null default 0,
  line_total numeric(12,2) not null default 0,
  variation jsonb,
  addons jsonb
);

create index if not exists idx_anaira_marketplace_business_active on public.anaira_marketplace_businesses(is_active, is_approved, marketplace_visible);
create index if not exists idx_anaira_hotel_inventory_date on public.anaira_hotel_inventory(inventory_date);
create index if not exists idx_anaira_marketplace_bookings_customer on public.anaira_marketplace_bookings(customer_user_id);
create index if not exists idx_anaira_marketplace_orders_customer on public.anaira_marketplace_orders(customer_user_id);
create index if not exists idx_anaira_marketplace_orders_restaurant on public.anaira_marketplace_orders(restaurant_id);

alter table public.anaira_marketplace_businesses enable row level security;
alter table public.anaira_hotel_properties enable row level security;
alter table public.anaira_hotel_room_types enable row level security;
alter table public.anaira_hotel_inventory enable row level security;
alter table public.anaira_marketplace_restaurants enable row level security;
alter table public.anaira_marketplace_menu_items enable row level security;
alter table public.anaira_marketplace_bookings enable row level security;
alter table public.anaira_marketplace_orders enable row level security;
alter table public.anaira_marketplace_order_items enable row level security;

create policy "marketplace public active businesses" on public.anaira_marketplace_businesses for select using (is_active and is_approved and marketplace_visible);
create policy "marketplace owners manage business" on public.anaira_marketplace_businesses for all using (owner_user_id = auth.uid()) with check (owner_user_id = auth.uid());

create policy "marketplace public hotel properties" on public.anaira_hotel_properties for select using (active and exists (select 1 from public.anaira_marketplace_businesses b where b.id=business_id and b.is_active and b.is_approved and b.marketplace_visible and b.hotel_booking_enabled));
create policy "marketplace public room types" on public.anaira_hotel_room_types for select using (active and exists (select 1 from public.anaira_hotel_properties p join public.anaira_marketplace_businesses b on b.id=p.business_id where p.id=property_id and p.active and b.is_active and b.is_approved and b.marketplace_visible and b.hotel_booking_enabled));
create policy "marketplace public inventory" on public.anaira_hotel_inventory for select using (exists (select 1 from public.anaira_hotel_room_types r join public.anaira_hotel_properties p on p.id=r.property_id join public.anaira_marketplace_businesses b on b.id=p.business_id where r.id=room_type_id and r.active and p.active and b.is_active and b.is_approved and b.marketplace_visible and b.hotel_booking_enabled));

create policy "marketplace public restaurants" on public.anaira_marketplace_restaurants for select using (active and exists (select 1 from public.anaira_marketplace_businesses b where b.id=business_id and b.is_active and b.is_approved and b.marketplace_visible and b.food_ordering_enabled));
create policy "marketplace public menu" on public.anaira_marketplace_menu_items for select using (active and exists (select 1 from public.anaira_marketplace_restaurants r join public.anaira_marketplace_businesses b on b.id=r.business_id where r.id=restaurant_id and r.active and b.is_active and b.is_approved and b.marketplace_visible and b.food_ordering_enabled));

create policy "customers see own bookings" on public.anaira_marketplace_bookings for select using (customer_user_id = auth.uid());
create policy "customers create own bookings" on public.anaira_marketplace_bookings for insert with check (customer_user_id = auth.uid());
create policy "customers update own bookings" on public.anaira_marketplace_bookings for update using (customer_user_id = auth.uid()) with check (customer_user_id = auth.uid());

create policy "customers see own orders" on public.anaira_marketplace_orders for select using (customer_user_id = auth.uid());
create policy "customers create own orders" on public.anaira_marketplace_orders for insert with check (customer_user_id = auth.uid());
create policy "customers update own orders" on public.anaira_marketplace_orders for update using (customer_user_id = auth.uid()) with check (customer_user_id = auth.uid());
create policy "customers see own order items" on public.anaira_marketplace_order_items for select using (exists (select 1 from public.anaira_marketplace_orders o where o.id=order_id and o.customer_user_id=auth.uid()));
create policy "customers create own order items" on public.anaira_marketplace_order_items for insert with check (exists (select 1 from public.anaira_marketplace_orders o where o.id=order_id and o.customer_user_id=auth.uid()));

comment on table public.anaira_marketplace_businesses is 'Unified Anaira marketplace business directory. Super Admin governs approval; Business Admin governs its own business.';
comment on table public.anaira_marketplace_bookings is 'Customer-facing booking contract. PMS remains operational reservation owner.';
comment on table public.anaira_marketplace_orders is 'Customer-facing food order contract. Anaira POS remains operational order/KOT owner.';
