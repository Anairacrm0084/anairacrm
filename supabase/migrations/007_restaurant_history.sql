create table if not exists public.crm_restaurant_visits (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  outlet_id uuid,
  table_number text,
  visit_at timestamptz not null default now(),
  guest_count integer default 1,
  order_id uuid,
  amount numeric(14,2) default 0,
  payment_method text
);

create table if not exists public.crm_food_preferences (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  preference_type text not null,
  value text not null,
  frequency numeric(12,2) default 0,
  confidence numeric(6,5),
  last_seen_at timestamptz default now(),
  unique(customer_id,preference_type,value)
);

alter table public.crm_restaurant_visits enable row level security;
alter table public.crm_food_preferences enable row level security;
create policy "restaurant_visits_auth" on public.crm_restaurant_visits for all to authenticated using (true) with check (true);
create policy "food_preferences_auth" on public.crm_food_preferences for all to authenticated using (true) with check (true);
