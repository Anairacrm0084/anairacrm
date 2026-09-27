-- Anaira Phase 19: production SEO + reputation runtime completion
create extension if not exists pgcrypto;

create table if not exists public.crm_seo_rank_history (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 keyword_id uuid references public.crm_seo_keywords(id) on delete cascade, tracked_at timestamptz not null default now(),
 search_engine text not null default 'google', country text default 'IN', city text, device text default 'desktop',
 position numeric, url text, serp_features jsonb default '[]'::jsonb, source text default 'provider'
);
create index if not exists crm_seo_rank_history_lookup on public.crm_seo_rank_history(site_id,keyword_id,tracked_at desc);

create table if not exists public.crm_seo_crawl_links (
 id uuid primary key default gen_random_uuid(), audit_id uuid references public.crm_seo_audits(id) on delete cascade,
 site_id uuid not null references public.crm_seo_sites(id) on delete cascade, source_url text not null, target_url text not null,
 link_type text not null default 'internal', anchor_text text, nofollow boolean default false, status_code integer,
 created_at timestamptz not null default now()
);
create index if not exists crm_seo_crawl_links_target on public.crm_seo_crawl_links(site_id,target_url);

create table if not exists public.crm_seo_link_suggestions (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_page_id uuid references public.crm_seo_pages(id) on delete cascade, target_page_id uuid references public.crm_seo_pages(id) on delete cascade,
 anchor_text text, reason text, confidence numeric default 0, status text not null default 'pending', created_at timestamptz default now(), applied_at timestamptz
);

create table if not exists public.crm_seo_schema_jobs (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 page_id uuid references public.crm_seo_pages(id) on delete cascade, schema_type text not null, schema_json jsonb not null,
 validation jsonb default '{}'::jsonb, status text not null default 'pending_approval', approved_by uuid, approved_at timestamptz,
 published_at timestamptz, created_at timestamptz default now()
);

create table if not exists public.crm_seo_content_versions (
 id uuid primary key default gen_random_uuid(), job_id uuid not null references public.crm_seo_content_jobs(id) on delete cascade,
 version_no integer not null, draft jsonb not null, created_by uuid, created_at timestamptz default now(), unique(job_id,version_no)
);

create table if not exists public.crm_seo_competitors (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 domain text not null, label text, active boolean default true, created_at timestamptz default now(), unique(site_id,domain)
);

create table if not exists public.crm_review_provider_sync (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, source_id uuid references public.crm_review_sources(id) on delete cascade,
 provider text not null, account_id text, cursor text, last_sync_at timestamptz, next_sync_at timestamptz, status text default 'idle',
 last_error text, attempts integer default 0, settings jsonb default '{}'::jsonb, created_at timestamptz default now(), unique(source_id)
);

create table if not exists public.crm_review_delivery_log (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, job_id uuid references public.crm_review_request_jobs(id) on delete set null,
 channel text not null, provider text, provider_message_id text, status text not null, attempt integer default 1, response jsonb,
 error text, created_at timestamptz default now()
);

create table if not exists public.crm_review_recovery_cases (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, review_id uuid not null references public.crm_reviews(id) on delete cascade,
 owner_id uuid, priority text default 'high', status text default 'open', reason text, resolution text, due_at timestamptz,
 resolved_at timestamptz, created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists public.crm_review_sla_events (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, recovery_case_id uuid references public.crm_review_recovery_cases(id) on delete cascade,
 event_type text not null, due_at timestamptz, actor_id uuid, notes text, created_at timestamptz default now()
);

create table if not exists public.crm_review_templates (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, name text not null, channel text not null,
 trigger text not null, body text not null, active boolean default true, created_at timestamptz default now()
);

create table if not exists public.crm_review_automation_runs (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, rule_id uuid references public.crm_review_automation_rules(id) on delete set null,
 reference_type text, reference_id text, status text default 'queued', attempts integer default 0, next_attempt_at timestamptz default now(),
 last_error text, created_at timestamptz default now(), completed_at timestamptz
);

alter table public.crm_review_request_jobs add column if not exists next_attempt_at timestamptz default now();
alter table public.crm_review_request_jobs add column if not exists consent_required boolean default true;
alter table public.crm_review_request_jobs add column if not exists consent_verified boolean default false;
alter table public.crm_review_request_jobs add column if not exists idempotency_key text;
alter table public.crm_review_request_jobs add column if not exists provider text;
create unique index if not exists crm_review_request_jobs_idempotency on public.crm_review_request_jobs(tenant_id,idempotency_key) where idempotency_key is not null;

alter table public.crm_seo_sites add column if not exists crawl_settings jsonb default '{"max_pages":500,"respect_robots":true,"render_js":false}'::jsonb;
alter table public.crm_seo_sites add column if not exists robots_rules jsonb default '[]'::jsonb;
alter table public.crm_seo_sites add column if not exists sitemap_settings jsonb default '{}'::jsonb;

-- RLS: child SEO records inherit tenant ownership through site.
do $$ declare t text; begin
 foreach t in array array['crm_seo_rank_history','crm_seo_crawl_links','crm_seo_link_suggestions','crm_seo_schema_jobs','crm_seo_content_versions','crm_seo_competitors'] loop
  execute format('alter table public.%I enable row level security',t);
 end loop;
 foreach t in array array['crm_review_provider_sync','crm_review_delivery_log','crm_review_recovery_cases','crm_review_sla_events','crm_review_templates','crm_review_automation_runs'] loop
  execute format('alter table public.%I enable row level security',t);
 end loop;
end $$;

-- Policies use the existing tenant helper where available; super-admin access is retained.
drop policy if exists tenant_access on public.crm_seo_rank_history;
create policy tenant_access on public.crm_seo_rank_history for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
drop policy if exists tenant_access on public.crm_seo_crawl_links;
create policy tenant_access on public.crm_seo_crawl_links for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
drop policy if exists tenant_access on public.crm_seo_link_suggestions;
create policy tenant_access on public.crm_seo_link_suggestions for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
drop policy if exists tenant_access on public.crm_seo_schema_jobs;
create policy tenant_access on public.crm_seo_schema_jobs for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));
drop policy if exists tenant_access on public.crm_seo_competitors;
create policy tenant_access on public.crm_seo_competitors for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)));

do $$ declare t text; begin foreach t in array array['crm_review_provider_sync','crm_review_delivery_log','crm_review_recovery_cases','crm_review_sla_events','crm_review_templates','crm_review_automation_runs'] loop execute format('drop policy if exists tenant_access on public.%I',t); execute format('create policy tenant_access on public.%I for all to authenticated using (public.anaira_tenant_access(tenant_id)) with check (public.anaira_tenant_access(tenant_id))',t); end loop; end $$;
