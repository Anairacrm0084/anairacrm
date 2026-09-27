create table if not exists public.crm_lead_activities (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  lead_id uuid not null references public.crm_leads(id) on delete cascade,
  activity_type text not null,
  subject text,
  notes text,
  actor_id uuid,
  occurred_at timestamptz default now()
);

create table if not exists public.crm_quotes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  lead_id uuid references public.crm_leads(id) on delete set null,
  quote_number text,
  status text default 'draft',
  subtotal numeric(14,2) default 0,
  discount numeric(14,2) default 0,
  tax numeric(14,2) default 0,
  total numeric(14,2) default 0,
  valid_until date,
  created_at timestamptz default now()
);

create table if not exists public.crm_followup_sequences (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  trigger_type text not null,
  active boolean default true,
  definition jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.crm_followup_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  lead_id uuid references public.crm_leads(id) on delete set null,
  sequence_id uuid references public.crm_followup_sequences(id) on delete set null,
  scheduled_at timestamptz,
  status text default 'pending',
  completed_at timestamptz
);

alter table public.crm_lead_activities enable row level security;
alter table public.crm_quotes enable row level security;
alter table public.crm_followup_sequences enable row level security;
alter table public.crm_followup_events enable row level security;
create policy "lead_activities_auth" on public.crm_lead_activities for all to authenticated using (true) with check (true);
create policy "quotes_auth" on public.crm_quotes for all to authenticated using (true) with check (true);
create policy "followup_sequences_auth" on public.crm_followup_sequences for all to authenticated using (true) with check (true);
create policy "followup_events_auth" on public.crm_followup_events for all to authenticated using (true) with check (true);
