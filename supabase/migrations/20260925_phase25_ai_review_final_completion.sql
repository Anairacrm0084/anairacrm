-- AI Review final hardening / production completion layer.
-- Does not seed business/demo records.

create table if not exists public.crm_review_google_connections (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null unique,
  account_id text,
  refresh_token text,
  scope text,
  connected_by uuid,
  connected_at timestamptz,
  pubsub_topic text,
  pubsub_enabled boolean not null default false,
  reply_automation_consent boolean not null default false,
  reply_automation_consent_at timestamptz,
  status text not null default 'connected',
  last_sync_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.crm_reviews
  add column if not exists google_review_name text,
  add column if not exists google_review_reply_url text,
  add column if not exists google_review_reply_state text,
  add column if not exists google_policy_violation jsonb,
  add column if not exists google_review_media jsonb not null default '[]'::jsonb,
  add column if not exists google_location_name text,
  add column if not exists google_account_id text,
  add column if not exists google_update_time timestamptz,
  add column if not exists google_content_expires_at timestamptz;

create index if not exists crm_reviews_google_expiry_idx
  on public.crm_reviews(google_content_expires_at)
  where google_content_expires_at is not null;

create unique index if not exists crm_reviews_google_name_uq
  on public.crm_reviews(tenant_id,google_review_name)
  where google_review_name is not null;

alter table public.crm_review_sources
  add column if not exists reply_automation_consent boolean not null default false,
  add column if not exists reply_automation_consent_at timestamptz,
  add column if not exists notification_enabled boolean not null default false;

alter table public.crm_review_templates
  add column if not exists version_no integer not null default 1,
  add column if not exists variables jsonb not null default '[]'::jsonb,
  add column if not exists created_by uuid,
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.crm_review_template_versions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  template_id uuid not null references public.crm_review_templates(id) on delete cascade,
  version_no integer not null,
  body text not null,
  variables jsonb not null default '[]'::jsonb,
  created_by uuid,
  created_at timestamptz not null default now(),
  unique(template_id,version_no)
);

create table if not exists public.crm_review_provider_actions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  review_id uuid references public.crm_reviews(id) on delete cascade,
  provider text not null,
  action text not null,
  idempotency_key text,
  status text not null,
  response jsonb not null default '{}'::jsonb,
  error text,
  actor_id uuid,
  created_at timestamptz not null default now()
);
create unique index if not exists crm_review_provider_actions_idempotency_uq
  on public.crm_review_provider_actions(tenant_id,idempotency_key)
  where idempotency_key is not null;

create table if not exists public.crm_review_webhook_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  provider text not null,
  event_key text not null,
  event_type text,
  payload jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  status text not null default 'received',
  error text,
  unique(provider,event_key)
);

create index if not exists crm_review_webhook_events_status_idx
  on public.crm_review_webhook_events(status,received_at);

create index if not exists crm_review_provider_actions_review_idx
  on public.crm_review_provider_actions(tenant_id,review_id,created_at desc);

alter table public.crm_review_google_connections enable row level security;
alter table public.crm_review_template_versions enable row level security;
alter table public.crm_review_provider_actions enable row level security;
alter table public.crm_review_webhook_events enable row level security;

do $$ begin
  drop policy if exists tenant_access on public.crm_review_template_versions;
  create policy tenant_access on public.crm_review_template_versions
    for all to authenticated using (anaira_tenant_access(tenant_id)) with check (anaira_tenant_access(tenant_id));
  drop policy if exists tenant_access on public.crm_review_provider_actions;
  create policy tenant_access on public.crm_review_provider_actions
    for all to authenticated using (anaira_tenant_access(tenant_id)) with check (anaira_tenant_access(tenant_id));
end $$;
alter table public.crm_review_request_jobs add column if not exists message text;
