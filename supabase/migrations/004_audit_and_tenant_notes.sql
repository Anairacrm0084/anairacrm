create table if not exists public.crm_audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  actor_id uuid,
  entity_type text not null,
  entity_id text,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

alter table public.crm_audit_logs enable row level security;
create policy "crm_audit_authenticated" on public.crm_audit_logs for select to authenticated using (true);

-- Production tenant isolation note:
-- The initial scaffold keeps tenant_id nullable because it must be mapped to
-- the user's existing Anaira tenant/restaurant identity. Before production,
-- replace broad authenticated policies with restaurant/tenant-scoped policies
-- using the existing Anaira profile/restaurant model.
