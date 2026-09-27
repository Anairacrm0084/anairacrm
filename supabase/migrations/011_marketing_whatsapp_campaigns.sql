create table if not exists public.crm_campaign_steps (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.crm_campaigns(id) on delete cascade,
  step_order integer not null,
  channel text not null,
  template_name text,
  delay_minutes integer default 0,
  content jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.crm_campaign_recipients (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.crm_campaigns(id) on delete cascade,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  status text default 'queued',
  sent_at timestamptz,
  delivered_at timestamptz,
  opened_at timestamptz,
  clicked_at timestamptz,
  converted_at timestamptz
);

create table if not exists public.crm_message_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  channel text not null,
  template_key text not null,
  provider_template_id text,
  language_code text default 'en',
  body text not null,
  variables jsonb default '[]'::jsonb,
  active boolean default true,
  created_at timestamptz default now(),
  unique(tenant_id,channel,template_key,language_code)
);

create table if not exists public.crm_message_log (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  channel text not null,
  direction text not null,
  template_id uuid references public.crm_message_templates(id) on delete set null,
  provider_message_id text,
  status text default 'queued',
  payload jsonb default '{}'::jsonb,
  sent_at timestamptz,
  created_at timestamptz default now()
);

alter table public.crm_campaign_steps enable row level security;
alter table public.crm_campaign_recipients enable row level security;
alter table public.crm_message_templates enable row level security;
alter table public.crm_message_log enable row level security;
create policy "campaign_steps_auth" on public.crm_campaign_steps for all to authenticated using (true) with check (true);
create policy "campaign_recipients_auth" on public.crm_campaign_recipients for all to authenticated using (true) with check (true);
create policy "message_templates_auth" on public.crm_message_templates for all to authenticated using (true) with check (true);
create policy "message_log_auth" on public.crm_message_log for all to authenticated using (true) with check (true);
