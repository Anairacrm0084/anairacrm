create extension if not exists pgcrypto;

create table if not exists public.crm_customers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  full_name text not null,
  phone text,
  email text,
  gender text,
  date_of_birth date,
  anniversary_date date,
  address_line1 text,
  city text,
  state text,
  country text default 'India',
  preferred_language text default 'en',
  customer_type text not null default 'guest',
  vip boolean not null default false,
  notes text,
  total_hotel_revenue numeric(14,2) not null default 0,
  total_restaurant_revenue numeric(14,2) not null default 0,
  total_stays integer not null default 0,
  total_restaurant_visits integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_crm_customers_tenant on public.crm_customers(tenant_id);
create index if not exists idx_crm_customers_phone on public.crm_customers(phone);
create index if not exists idx_crm_customers_email on public.crm_customers(email);

create table if not exists public.crm_customer_preferences (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  preference_key text not null,
  preference_value text,
  source text default 'manual',
  confidence numeric(5,4),
  created_at timestamptz not null default now(),
  unique(customer_id, preference_key)
);

create table if not exists public.crm_tags (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_customer_tags (
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  tag_id uuid not null references public.crm_tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(customer_id, tag_id)
);

create table if not exists public.crm_interactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  channel text not null,
  interaction_type text not null,
  subject text,
  notes text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.crm_tasks (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.crm_customers(id) on delete set null,
  tenant_id uuid,
  title text not null,
  status text not null default 'open',
  priority text not null default 'normal',
  due_at timestamptz,
  assigned_to uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_complaints (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.crm_customers(id) on delete set null,
  tenant_id uuid,
  title text not null,
  description text,
  priority text not null default 'normal',
  status text not null default 'open',
  resolution text,
  opened_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.crm_feedback (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.crm_customers(id) on delete set null,
  tenant_id uuid,
  overall_rating numeric(3,2),
  room_rating numeric(3,2),
  food_rating numeric(3,2),
  service_rating numeric(3,2),
  cleanliness_rating numeric(3,2),
  comment text,
  source text,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_consents (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  channel text not null,
  purpose text not null,
  status text not null default 'pending',
  captured_at timestamptz,
  source text,
  unique(customer_id, channel, purpose)
);

alter table public.crm_customers enable row level security;
alter table public.crm_customer_preferences enable row level security;
alter table public.crm_tags enable row level security;
alter table public.crm_customer_tags enable row level security;
alter table public.crm_interactions enable row level security;
alter table public.crm_tasks enable row level security;
alter table public.crm_complaints enable row level security;
alter table public.crm_feedback enable row level security;
alter table public.crm_consents enable row level security;

create policy "crm_customers_authenticated" on public.crm_customers for all to authenticated using (true) with check (true);
create policy "crm_preferences_authenticated" on public.crm_customer_preferences for all to authenticated using (true) with check (true);
create policy "crm_tags_authenticated" on public.crm_tags for all to authenticated using (true) with check (true);
create policy "crm_customer_tags_authenticated" on public.crm_customer_tags for all to authenticated using (true) with check (true);
create policy "crm_interactions_authenticated" on public.crm_interactions for all to authenticated using (true) with check (true);
create policy "crm_tasks_authenticated" on public.crm_tasks for all to authenticated using (true) with check (true);
create policy "crm_complaints_authenticated" on public.crm_complaints for all to authenticated using (true) with check (true);
create policy "crm_feedback_authenticated" on public.crm_feedback for all to authenticated using (true) with check (true);
create policy "crm_consents_authenticated" on public.crm_consents for all to authenticated using (true) with check (true);

comment on table public.crm_customers is 'Anaira CRM customer master. tenant_id must be enforced by production tenant/RLS integration.';
