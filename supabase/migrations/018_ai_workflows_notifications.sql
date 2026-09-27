create table if not exists public.crm_ai_insights (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  insight_type text not null,
  summary text not null,
  recommendation text,
  confidence numeric(6,5),
  model_name text,
  model_version text,
  input_snapshot jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.crm_workflows (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  trigger_type text not null,
  active boolean default true,
  definition jsonb not null default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.crm_workflow_runs (
  id uuid primary key default gen_random_uuid(),
  workflow_id uuid not null references public.crm_workflows(id) on delete cascade,
  tenant_id uuid,
  status text default 'queued',
  context jsonb default '{}'::jsonb,
  started_at timestamptz,
  completed_at timestamptz,
  error text
);

create table if not exists public.crm_notifications (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  user_id uuid,
  notification_type text not null,
  title text not null,
  body text,
  severity text default 'info',
  read_at timestamptz,
  action_url text,
  created_at timestamptz default now()
);

alter table public.crm_ai_insights enable row level security;
alter table public.crm_workflows enable row level security;
alter table public.crm_workflow_runs enable row level security;
alter table public.crm_notifications enable row level security;
create policy "ai_insights_auth" on public.crm_ai_insights for all to authenticated using (true) with check (true);
create policy "workflows_auth" on public.crm_workflows for all to authenticated using (true) with check (true);
create policy "workflow_runs_auth" on public.crm_workflow_runs for all to authenticated using (true) with check (true);
create policy "notifications_auth" on public.crm_notifications for all to authenticated using (true) with check (true);
