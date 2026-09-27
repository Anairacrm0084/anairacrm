create table if not exists public.crm_compliance_audit (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  actor_id uuid,
  action text not null,
  entity_type text not null,
  entity_id text,
  before_data jsonb,
  after_data jsonb,
  ip_hash text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists idx_crm_compliance_audit_entity on public.crm_compliance_audit(entity_type,entity_id,created_at desc);

alter table public.crm_compliance_audit enable row level security;
create policy "compliance_audit_read_auth" on public.crm_compliance_audit for select to authenticated using (true);
