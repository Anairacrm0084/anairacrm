create table if not exists public.crm_timeline_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  event_type text not null,
  source_system text not null,
  source_id text,
  title text not null,
  description text,
  amount numeric(14,2),
  metadata jsonb default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  created_at timestamptz default now()
);

create index if not exists idx_crm_timeline_customer_date on public.crm_timeline_events(customer_id,occurred_at desc);

alter table public.crm_timeline_events enable row level security;
create policy "timeline_events_auth" on public.crm_timeline_events for all to authenticated using (true) with check (true);
