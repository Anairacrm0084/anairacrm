-- Phase 19 real-integration hardening
create table if not exists public.crm_seo_gsc_metrics (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 metric_date date not null, query text, page text, country text, device text, search_appearance text,
 clicks integer default 0, impressions integer default 0, ctr numeric default 0, position numeric,
 created_at timestamptz default now(), unique(site_id,metric_date,query,page,country,device,search_appearance)
);
create table if not exists public.crm_seo_ga4_metrics (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 metric_date date not null, channel text, landing_page text, sessions integer default 0, users integer default 0,
 conversions numeric default 0, created_at timestamptz default now(), unique(site_id,metric_date,channel,landing_page)
);
alter table public.crm_seo_gsc_metrics enable row level security;
alter table public.crm_seo_ga4_metrics enable row level security;
drop policy if exists tenant_access on public.crm_seo_gsc_metrics;
create policy tenant_access on public.crm_seo_gsc_metrics for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
drop policy if exists tenant_access on public.crm_seo_ga4_metrics;
create policy tenant_access on public.crm_seo_ga4_metrics for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
