create table if not exists public.crm_partner_settlements (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, partner_id uuid not null,
  period_start date not null, period_end date not null, gross_amount numeric not null default 0,
  commission_amount numeric not null default 0, status text not null default 'pending',
  created_at timestamptz not null default now(), settled_at timestamptz
);
alter table public.crm_revenue_forecasts add column if not exists status text not null default 'draft';
alter table public.crm_revenue_forecasts add column if not exists approved_by uuid;
alter table public.crm_revenue_forecasts add column if not exists approved_at timestamptz;
alter table public.crm_revenue_forecasts add column if not exists published_at timestamptz;
alter table public.crm_partner_settlements enable row level security;
drop policy if exists crm_partner_settlements_tenant_access on public.crm_partner_settlements;
create policy crm_partner_settlements_tenant_access on public.crm_partner_settlements for all to authenticated using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));
create index if not exists crm_partner_settlements_tenant_idx on public.crm_partner_settlements(tenant_id,period_end desc);
