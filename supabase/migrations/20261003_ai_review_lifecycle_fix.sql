-- AI Review lifecycle correctness fixes. Idempotent and credential-independent.
-- Webhook retry bookkeeping prevents failed processing from being acknowledged as successful.
alter table public.crm_review_webhook_events add column if not exists attempts integer not null default 0;
alter table public.crm_review_webhook_events add column if not exists next_attempt_at timestamptz;
create index if not exists crm_review_webhook_events_retry_idx on public.crm_review_webhook_events(status,next_attempt_at,received_at);

-- Keep recovery lifecycle explicit for UI/API operations.
alter table public.crm_review_recovery_cases add column if not exists resolved_at timestamptz;
alter table public.crm_review_recovery_cases add column if not exists updated_at timestamptz not null default now();
alter table public.crm_review_recovery_cases add column if not exists owner_id uuid;
