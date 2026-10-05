-- Dedicated Complaint Management + Service Recovery runtime.
-- Reuses existing crm_complaints; adds a separate recovery case lifecycle.
create table if not exists public.crm_service_recovery_cases (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  property_id uuid,
  complaint_id uuid,
  customer_id uuid,
  status text not null default 'open',
  recovery_type text,
  compensation_amount numeric(14,2) not null default 0,
  approved_by uuid,
  outcome text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_crm_recovery_tenant_property on public.crm_service_recovery_cases(tenant_id,property_id,created_at desc);
alter table public.crm_service_recovery_cases enable row level security;
drop policy if exists crm_recovery_tenant on public.crm_service_recovery_cases;
create policy crm_recovery_tenant on public.crm_service_recovery_cases for all to authenticated using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));
revoke all on public.crm_service_recovery_cases from anon;
grant select,insert,update,delete on public.crm_service_recovery_cases to authenticated;
