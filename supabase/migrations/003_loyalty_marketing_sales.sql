create table if not exists public.crm_loyalty_accounts (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null unique references public.crm_customers(id) on delete cascade,
  tenant_id uuid,
  tier text not null default 'bronze',
  points_balance integer not null default 0,
  lifetime_points integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  loyalty_account_id uuid not null references public.crm_loyalty_accounts(id) on delete cascade,
  points integer not null,
  transaction_type text not null,
  reference_type text,
  reference_id text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_rewards (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  points_cost integer not null,
  reward_type text not null,
  reward_value numeric(12,2),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_segments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  definition jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_campaigns (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  channel text not null,
  segment_id uuid references public.crm_segments(id) on delete set null,
  status text not null default 'draft',
  scheduled_at timestamptz,
  offer_code text,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_leads (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  lead_type text not null,
  source text,
  stage text not null default 'new',
  estimated_value numeric(14,2),
  next_follow_up timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_corporate_accounts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  company_name text not null,
  contact_name text,
  phone text,
  email text,
  negotiated_rate_notes text,
  payment_terms text,
  credit_limit numeric(14,2),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_partners (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  partner_type text not null,
  name text not null,
  contact_name text,
  phone text,
  email text,
  commission_percent numeric(7,3),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.crm_loyalty_accounts enable row level security;
alter table public.crm_loyalty_transactions enable row level security;
alter table public.crm_rewards enable row level security;
alter table public.crm_segments enable row level security;
alter table public.crm_campaigns enable row level security;
alter table public.crm_leads enable row level security;
alter table public.crm_corporate_accounts enable row level security;
alter table public.crm_partners enable row level security;

create policy "loyalty_accounts_authenticated" on public.crm_loyalty_accounts for all to authenticated using (true) with check (true);
create policy "loyalty_transactions_authenticated" on public.crm_loyalty_transactions for all to authenticated using (true) with check (true);
create policy "rewards_authenticated" on public.crm_rewards for all to authenticated using (true) with check (true);
create policy "segments_authenticated" on public.crm_segments for all to authenticated using (true) with check (true);
create policy "campaigns_authenticated" on public.crm_campaigns for all to authenticated using (true) with check (true);
create policy "leads_authenticated" on public.crm_leads for all to authenticated using (true) with check (true);
create policy "corporate_accounts_authenticated" on public.crm_corporate_accounts for all to authenticated using (true) with check (true);
create policy "partners_authenticated" on public.crm_partners for all to authenticated using (true) with check (true);
