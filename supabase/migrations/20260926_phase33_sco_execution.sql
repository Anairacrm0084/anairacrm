create table if not exists public.crm_seo_sco_runs(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 status text not null default 'queued', source_summary jsonb not null default '{}'::jsonb, candidate_count integer not null default 0,
 created_at timestamptz not null default now(), completed_at timestamptz
);
create table if not exists public.crm_seo_sco_opportunities(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 run_id uuid references public.crm_seo_sco_runs(id) on delete set null, keyword text not null,
 search_volume numeric, gap_score numeric, intent text, target_url text, has_target_page boolean not null default false,
 source text, opportunity_score numeric not null default 0, recommended_action text, recommended_slug text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(site_id,keyword)
);
create index if not exists crm_seo_sco_runs_site_idx on public.crm_seo_sco_runs(site_id,created_at desc);
create index if not exists crm_seo_sco_opportunities_score_idx on public.crm_seo_sco_opportunities(site_id,opportunity_score desc);
alter table public.crm_seo_sco_runs enable row level security;
alter table public.crm_seo_sco_opportunities enable row level security;
drop policy if exists tenant_access on public.crm_seo_sco_runs;
drop policy if exists tenant_access on public.crm_seo_sco_opportunities;
create policy tenant_access on public.crm_seo_sco_runs for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
create policy tenant_access on public.crm_seo_sco_opportunities for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
create unique index if not exists crm_seo_web_index_links_identity on public.crm_seo_web_index_links(site_id,source_url,target_url,anchor_text);
create unique index if not exists crm_seo_citation_records_identity on public.crm_seo_citation_records(site_id,directory,listing_url);
