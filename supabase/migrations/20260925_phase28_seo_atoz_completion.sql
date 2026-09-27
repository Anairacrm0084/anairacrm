-- Phase 28 SEO A-to-Z completion hardening
alter table public.crm_seo_issues add column if not exists url text;
alter table public.crm_seo_issues add column if not exists evidence jsonb not null default '{}'::jsonb;
alter table public.crm_seo_issues add column if not exists checked_at timestamptz;
create unique index if not exists crm_seo_issues_site_fingerprint_uq on public.crm_seo_issues(site_id,fingerprint) where fingerprint is not null;

alter table public.crm_seo_redirects add column if not exists updated_at timestamptz not null default now();
alter table public.crm_seo_redirects add column if not exists notes text;
alter table public.crm_seo_redirects add column if not exists last_tested_at timestamptz;
alter table public.crm_seo_redirects add column if not exists last_test_status text;
alter table public.crm_seo_redirects add column if not exists last_test_status_code integer;
create unique index if not exists crm_seo_redirects_source_uq on public.crm_seo_redirects(site_id,source_path);

create table if not exists public.crm_seo_redirect_history(
  id uuid primary key default gen_random_uuid(),
  redirect_id uuid not null references public.crm_seo_redirects(id) on delete cascade,
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  action text not null,
  before_data jsonb not null default '{}'::jsonb,
  after_data jsonb not null default '{}'::jsonb,
  actor_id uuid,
  created_at timestamptz not null default now()
);
create index if not exists crm_seo_redirect_history_idx on public.crm_seo_redirect_history(redirect_id,created_at desc);

create table if not exists public.crm_seo_audit_comparisons(
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  previous_audit_id uuid references public.crm_seo_audits(id) on delete set null,
  current_audit_id uuid not null references public.crm_seo_audits(id) on delete cascade,
  score_delta numeric,
  new_issues integer not null default 0,
  resolved_issues integer not null default 0,
  regressed_issues integer not null default 0,
  persistent_issues integer not null default 0,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists crm_seo_audit_comparisons_idx on public.crm_seo_audit_comparisons(site_id,created_at desc);

alter table public.crm_seo_pages add column if not exists orphan boolean not null default false;
alter table public.crm_seo_pages add column if not exists status_code_family text;
alter table public.crm_seo_pages add column if not exists canonical_conflict boolean not null default false;

alter table public.crm_seo_rank_history add column if not exists city text;
alter table public.crm_seo_rank_history add column if not exists location text;
alter table public.crm_seo_rank_history add column if not exists rank_source text default 'serpapi';
alter table public.crm_seo_rank_history add column if not exists visibility numeric;
alter table public.crm_seo_rank_history add column if not exists share_of_voice numeric;

alter table public.crm_seo_report_runs add column if not exists pdf_storage_path text;
alter table public.crm_seo_report_runs add column if not exists delivery_status text default 'pending';
alter table public.crm_seo_report_runs add column if not exists generated_at timestamptz;

alter table public.crm_seo_local_locations add column if not exists connected_at timestamptz;
alter table public.crm_seo_local_locations add column if not exists last_sync_at timestamptz;

do $$ declare t text; begin
  foreach t in array array['crm_seo_redirect_history','crm_seo_audit_comparisons'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('drop policy if exists tenant_access on public.%I',t);
    execute format('create policy tenant_access on public.%I for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)))',t);
  end loop;
end $$;

alter table public.crm_seo_rank_history add column if not exists device text default 'desktop';
alter table public.crm_seo_pages add column if not exists serps_preview jsonb not null default '{}'::jsonb;

create table if not exists public.crm_seo_issue_history(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  issue_id uuid references public.crm_seo_issues(id) on delete cascade, action text not null,
  before_data jsonb not null default '{}'::jsonb, after_data jsonb not null default '{}'::jsonb,
  actor_id uuid, created_at timestamptz not null default now()
);
create index if not exists crm_seo_issue_history_idx on public.crm_seo_issue_history(site_id,issue_id,created_at desc);

create table if not exists public.crm_seo_keyword_cannibalization(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  keyword text not null, pages jsonb not null default '[]'::jsonb, severity text not null default 'warning',
  winner_url text, evidence jsonb not null default '{}'::jsonb, status text not null default 'open', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists crm_seo_keyword_cannibalization_idx on public.crm_seo_keyword_cannibalization(site_id,status,keyword);

create table if not exists public.crm_seo_keyword_clusters(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  name text not null, parent_topic text, intent text, keyword_ids jsonb not null default '[]'::jsonb,
  target_url text, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(site_id,name)
);

create table if not exists public.crm_seo_gsc_inspections(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  url text not null, inspection_date timestamptz not null default now(), index_status text, coverage_state text,
  robots_txt_state text, indexing_state text, verdict text, canonical text, mobile_usability jsonb not null default '{}'::jsonb,
  rich_results jsonb not null default '[]'::jsonb, raw jsonb not null default '{}'::jsonb
);
create index if not exists crm_seo_gsc_inspections_idx on public.crm_seo_gsc_inspections(site_id,url,inspection_date desc);

create table if not exists public.crm_seo_local_citations(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  provider text not null, listing_url text, business_name text, address jsonb not null default '{}'::jsonb,
  phone text, status text not null default 'unknown', nap_match boolean, checked_at timestamptz not null default now(), raw jsonb not null default '{}'::jsonb
);
create index if not exists crm_seo_local_citations_idx on public.crm_seo_local_citations(site_id,provider);

create table if not exists public.crm_seo_schema_validations(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  page_id uuid references public.crm_seo_pages(id) on delete cascade, provider text not null, status text not null,
  errors jsonb not null default '[]'::jsonb, warnings jsonb not null default '[]'::jsonb, response jsonb not null default '{}'::jsonb,
  checked_at timestamptz not null default now()
);

create table if not exists public.crm_seo_link_change_history(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  suggestion_id uuid references public.crm_seo_link_suggestions(id) on delete set null, action text not null,
  before_data jsonb not null default '{}'::jsonb, after_data jsonb not null default '{}'::jsonb, actor_id uuid, created_at timestamptz not null default now()
);

create table if not exists public.crm_seo_content_briefs(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  keyword text not null, target_url text, title_ideas jsonb not null default '[]'::jsonb, questions jsonb not null default '[]'::jsonb,
  entities jsonb not null default '[]'::jsonb, competitor_urls jsonb not null default '[]'::jsonb, word_count_target integer,
  brief jsonb not null default '{}'::jsonb, status text not null default 'draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.crm_seo_content_optimizations(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  page_id uuid references public.crm_seo_pages(id) on delete cascade, keyword text, score numeric, readability numeric,
  topic_coverage numeric, entities jsonb not null default '[]'::jsonb, recommendations jsonb not null default '[]'::jsonb, content_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_seo_automation_workflows(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  name text not null, enabled boolean not null default true, trigger_type text not null, trigger_config jsonb not null default '{}'::jsonb,
  actions jsonb not null default '[]'::jsonb, timezone text not null default 'Asia/Kolkata', last_run_at timestamptz, next_run_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists crm_seo_automation_workflows_idx on public.crm_seo_automation_workflows(site_id,enabled,next_run_at);

create table if not exists public.crm_seo_deployment_targets(
  id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  target_type text not null, endpoint text, provider text, settings jsonb not null default '{}'::jsonb,
  status text not null default 'not_configured', last_deployed_at timestamptz, last_error text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(site_id,target_type)
);

do $$ declare t text; begin
  foreach t in array array['crm_seo_issue_history','crm_seo_keyword_cannibalization','crm_seo_keyword_clusters','crm_seo_gsc_inspections','crm_seo_local_citations','crm_seo_schema_validations','crm_seo_link_change_history','crm_seo_content_briefs','crm_seo_content_optimizations','crm_seo_automation_workflows','crm_seo_deployment_targets'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('drop policy if exists tenant_access on public.%I',t);
    execute format('create policy tenant_access on public.%I for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)))',t);
  end loop;
end $$;
