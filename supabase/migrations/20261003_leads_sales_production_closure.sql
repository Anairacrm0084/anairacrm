-- Anaira Leads & Sales production closure: scoring, assignment, opportunity state, attribution, forecast.
-- Safe additive migration; existing CRM migrations/functions are preserved.
alter table public.crm_leads add column if not exists owner_id uuid;
alter table public.crm_leads add column if not exists lead_score numeric default 0;
alter table public.crm_leads add column if not exists score_reason jsonb default '{}'::jsonb;
alter table public.crm_leads add column if not exists company_name text;
alter table public.crm_leads add column if not exists email text;
alter table public.crm_leads add column if not exists phone text;
create index if not exists crm_leads_owner_idx on public.crm_leads(tenant_id,property_id,owner_id,stage);
alter table public.crm_opportunities add column if not exists owner_id uuid;
alter table public.crm_opportunities add column if not exists company_name text;
alter table public.crm_opportunities add column if not exists stage text;
alter table public.crm_opportunities add column if not exists win_loss_reason text;
alter table public.crm_opportunities add column if not exists closed_at timestamptz;
alter table public.crm_opportunities add column if not exists weighted_value numeric generated always as (coalesce(value,0)*coalesce(probability,0)/100) stored;
create index if not exists crm_opportunities_pipeline_idx on public.crm_opportunities(tenant_id,property_id,stage,expected_close_at);
create table if not exists public.crm_sales_opportunity_history(id uuid primary key default gen_random_uuid(),tenant_id uuid not null,property_id uuid,opportunity_id uuid not null references public.crm_opportunities(id) on delete cascade,from_stage text,to_stage text not null,reason text,changed_by uuid,changed_at timestamptz not null default now());
alter table public.crm_sales_opportunity_history enable row level security;
drop policy if exists tenant_access on public.crm_sales_opportunity_history;
create policy tenant_access on public.crm_sales_opportunity_history for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create table if not exists public.crm_sales_revenue_attribution(id uuid primary key default gen_random_uuid(),tenant_id uuid not null,property_id uuid,lead_id uuid,opportunity_id uuid,quote_id uuid,customer_id uuid,revenue numeric not null default 0,attribution_type text not null,source text,idempotency_key text not null,metadata jsonb not null default '{}'::jsonb,created_at timestamptz not null default now(),unique(tenant_id,idempotency_key));
alter table public.crm_sales_revenue_attribution enable row level security;
drop policy if exists tenant_access on public.crm_sales_revenue_attribution;
create policy tenant_access on public.crm_sales_revenue_attribution for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create table if not exists public.crm_sales_forecast_snapshots(id uuid primary key default gen_random_uuid(),tenant_id uuid not null,property_id uuid,as_of_date date not null default current_date,pipeline_value numeric not null default 0,weighted_pipeline numeric not null default 0,won_revenue numeric not null default 0,open_deals integer not null default 0,won_deals integer not null default 0,lost_deals integer not null default 0,forecast_revenue numeric not null default 0,model_version text not null default 'pipeline-weighted-v1',created_at timestamptz not null default now());
alter table public.crm_sales_forecast_snapshots enable row level security;
drop policy if exists tenant_access on public.crm_sales_forecast_snapshots;
create policy tenant_access on public.crm_sales_forecast_snapshots for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
