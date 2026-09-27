create table if not exists public.crm_segment_members (
  segment_id uuid not null references public.crm_segments(id) on delete cascade,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  calculated_at timestamptz default now(),
  reason jsonb default '{}'::jsonb,
  primary key(segment_id,customer_id)
);

create table if not exists public.crm_churn_scores (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  score numeric(6,5) not null,
  risk_level text not null,
  factors jsonb default '[]'::jsonb,
  calculated_at timestamptz default now()
);

create table if not exists public.crm_vip_profiles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null unique references public.crm_customers(id) on delete cascade,
  vip_level text not null default 'vip',
  dedicated_manager uuid,
  welcome_amenities jsonb default '[]'::jsonb,
  complimentary_services jsonb default '[]'::jsonb,
  notes text,
  created_at timestamptz default now()
);

alter table public.crm_segment_members enable row level security;
alter table public.crm_churn_scores enable row level security;
alter table public.crm_vip_profiles enable row level security;
create policy "segment_members_auth" on public.crm_segment_members for all to authenticated using (true) with check (true);
create policy "churn_scores_auth" on public.crm_churn_scores for all to authenticated using (true) with check (true);
create policy "vip_profiles_auth" on public.crm_vip_profiles for all to authenticated using (true) with check (true);
