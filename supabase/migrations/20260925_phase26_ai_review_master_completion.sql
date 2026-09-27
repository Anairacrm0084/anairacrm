-- AI Review master completion migration. All statements are idempotent for clean installs.
create table if not exists public.crm_review_ai_runs (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, review_id uuid references public.crm_reviews(id) on delete cascade,
  model_name text not null, model_version text, prompt_version text not null default 'v1', input_snapshot jsonb not null default '{}'::jsonb,
  output jsonb not null default '{}'::jsonb, status text not null default 'completed', error text, input_tokens integer, output_tokens integer,
  total_tokens integer, latency_ms integer, google_content_expires_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.crm_review_recovery_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, recovery_case_id uuid not null references public.crm_review_recovery_cases(id) on delete cascade,
  event_type text not null, actor_id uuid, from_status text, to_status text, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create table if not exists public.crm_review_automation_action_runs (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, rule_id uuid references public.crm_review_automation_rules(id) on delete set null,
  automation_run_id uuid references public.crm_review_automation_runs(id) on delete cascade, action_type text not null, status text not null default 'queued',
  idempotency_key text, result jsonb not null default '{}'::jsonb, error text, google_content_expires_at timestamptz, created_at timestamptz not null default now(), completed_at timestamptz
);
create table if not exists public.crm_review_template_versions (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, template_id uuid not null references public.crm_review_templates(id) on delete cascade,
  version_no integer not null, body text not null, variables jsonb not null default '[]'::jsonb, created_by uuid, created_at timestamptz not null default now(), unique(template_id,version_no)
);
create table if not exists public.crm_review_provider_actions (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, review_id uuid references public.crm_reviews(id) on delete cascade,
  provider text not null, action text not null, idempotency_key text, status text not null, response jsonb not null default '{}'::jsonb, error text, actor_id uuid,
  google_content_expires_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.crm_review_webhook_events (
  id uuid primary key default gen_random_uuid(), tenant_id uuid, provider text not null, event_key text not null, event_type text,
  payload jsonb not null default '{}'::jsonb, received_at timestamptz not null default now(), processed_at timestamptz, status text not null default 'received', error text,
  google_content_expires_at timestamptz, unique(provider,event_key)
);
create table if not exists public.crm_review_google_connections (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null unique, account_id text, refresh_token text, scope text, connected_by uuid,
  connected_at timestamptz, pubsub_topic text, pubsub_enabled boolean not null default false, reply_automation_consent boolean not null default false,
  reply_automation_consent_at timestamptz, status text not null default 'connected', last_sync_at timestamptz, last_error text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
do $$ begin
  alter table public.crm_reviews add column if not exists google_review_name text;
  alter table public.crm_reviews add column if not exists google_review_reply_url text;
  alter table public.crm_reviews add column if not exists google_review_reply_state text;
  alter table public.crm_reviews add column if not exists google_policy_violation jsonb;
  alter table public.crm_reviews add column if not exists google_review_media jsonb not null default '[]'::jsonb;
  alter table public.crm_reviews add column if not exists google_location_name text;
  alter table public.crm_reviews add column if not exists google_account_id text;
  alter table public.crm_reviews add column if not exists google_update_time timestamptz;
  alter table public.crm_reviews add column if not exists google_content_expires_at timestamptz;
  alter table public.crm_review_ai_actions add column if not exists google_content_expires_at timestamptz;
  alter table public.crm_review_recovery_cases add column if not exists google_content_expires_at timestamptz;
  alter table public.crm_review_automation_runs add column if not exists google_content_expires_at timestamptz;
  alter table public.crm_review_request_jobs add column if not exists message text;
  alter table public.crm_review_provider_actions add column if not exists google_content_expires_at timestamptz;
  alter table public.crm_review_webhook_events add column if not exists google_content_expires_at timestamptz;
end $$;

create unique index if not exists crm_reviews_google_name_uq on public.crm_reviews(tenant_id,google_review_name) where google_review_name is not null;
create unique index if not exists crm_review_provider_actions_idempotency_uq on public.crm_review_provider_actions(tenant_id,idempotency_key) where idempotency_key is not null;
create unique index if not exists crm_review_automation_action_idempotency_uq on public.crm_review_automation_action_runs(tenant_id,idempotency_key) where idempotency_key is not null;
create index if not exists crm_review_ai_runs_tenant_idx on public.crm_review_ai_runs(tenant_id,created_at desc);
create index if not exists crm_review_recovery_events_case_idx on public.crm_review_recovery_events(recovery_case_id,created_at desc);
create index if not exists crm_review_webhook_events_status_idx on public.crm_review_webhook_events(status,received_at);

alter table public.crm_review_ai_runs enable row level security;
alter table public.crm_review_recovery_events enable row level security;
alter table public.crm_review_automation_action_runs enable row level security;
alter table public.crm_review_template_versions enable row level security;
alter table public.crm_review_provider_actions enable row level security;
alter table public.crm_review_webhook_events enable row level security;
alter table public.crm_review_google_connections enable row level security;

do $$ begin
  drop policy if exists tenant_access on public.crm_review_ai_runs;
  create policy tenant_access on public.crm_review_ai_runs for all to authenticated using (anaira_tenant_access(tenant_id)) with check (anaira_tenant_access(tenant_id));
  drop policy if exists tenant_access on public.crm_review_recovery_events;
  create policy tenant_access on public.crm_review_recovery_events for all to authenticated using (anaira_tenant_access(tenant_id)) with check (anaira_tenant_access(tenant_id));
  drop policy if exists tenant_access on public.crm_review_automation_action_runs;
  create policy tenant_access on public.crm_review_automation_action_runs for all to authenticated using (anaira_tenant_access(tenant_id)) with check (anaira_tenant_access(tenant_id));
  drop policy if exists tenant_access on public.crm_review_template_versions;
  create policy tenant_access on public.crm_review_template_versions for all to authenticated using (anaira_tenant_access(tenant_id)) with check (anaira_tenant_access(tenant_id));
  drop policy if exists tenant_access on public.crm_review_provider_actions;
  create policy tenant_access on public.crm_review_provider_actions for all to authenticated using (anaira_tenant_access(tenant_id)) with check (anaira_tenant_access(tenant_id));
end $$;
