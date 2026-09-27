create table if not exists public.crm_loyalty_tiers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  min_lifetime_points integer default 0,
  benefits jsonb default '{}'::jsonb,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.crm_coupon_definitions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  code text not null,
  name text not null,
  discount_type text not null,
  discount_value numeric(14,2) not null,
  max_redemptions integer,
  per_customer_limit integer,
  starts_at timestamptz,
  ends_at timestamptz,
  eligibility jsonb default '{}'::jsonb,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.crm_coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  coupon_id uuid not null references public.crm_coupon_definitions(id) on delete cascade,
  customer_id uuid references public.crm_customers(id) on delete set null,
  reference_type text,
  reference_id text,
  discount_amount numeric(14,2) default 0,
  redeemed_at timestamptz default now()
);

create table if not exists public.crm_referrals (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  referrer_customer_id uuid references public.crm_customers(id) on delete set null,
  referred_customer_id uuid references public.crm_customers(id) on delete set null,
  status text default 'pending',
  reward_points integer default 0,
  created_at timestamptz default now()
);

alter table public.crm_loyalty_tiers enable row level security;
alter table public.crm_coupon_definitions enable row level security;
alter table public.crm_coupon_redemptions enable row level security;
alter table public.crm_referrals enable row level security;
create policy "loyalty_tiers_auth" on public.crm_loyalty_tiers for all to authenticated using (true) with check (true);
create policy "coupon_definitions_auth" on public.crm_coupon_definitions for all to authenticated using (true) with check (true);
create policy "coupon_redemptions_auth" on public.crm_coupon_redemptions for all to authenticated using (true) with check (true);
create policy "referrals_auth" on public.crm_referrals for all to authenticated using (true) with check (true);
