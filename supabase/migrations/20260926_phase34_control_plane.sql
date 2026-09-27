create extension if not exists pgcrypto;

-- Market-parity data layer required by Phase 32/33 runtime.
create table if not exists public.crm_seo_web_index_pages(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 url text not null, normalized_url text not null, status_code integer, content_type text, title text, content_hash text,
 word_count integer default 0, crawl_depth integer default 0, first_seen_at timestamptz default now(), last_seen_at timestamptz default now(),
 last_crawled_at timestamptz default now(), headers jsonb not null default '{}', extracted jsonb not null default '{}', snapshot jsonb not null default '{}',
 unique(site_id,normalized_url));
create table if not exists public.crm_seo_web_index_links(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_url text not null, target_url text not null, anchor_text text, rel text, first_seen_at timestamptz default now(), last_seen_at timestamptz default now(), attributes jsonb not null default '{}');
create table if not exists public.crm_seo_keyword_index(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, locale text default 'en-IN', country text, city text, device text default 'desktop', language text,
 volume numeric, difficulty numeric, cpc numeric, intent text, trend jsonb not null default '{}', seasonality jsonb not null default '{}', questions jsonb not null default '[]', related jsonb not null default '[]', cluster text, source text, source_ref text, observed_at timestamptz default now(), unique(site_id,keyword,locale,device));
create table if not exists public.crm_seo_serp_index(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, engine text not null, locale text, device text, captured_at timestamptz default now(), position integer, url text, domain text, title text, snippet text, feature text, citation_url text, provider text, raw jsonb not null default '{}');
create table if not exists public.crm_seo_backlink_index(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_url text not null, target_url text not null, source_domain text, anchor text, rel text, first_seen_at timestamptz, last_seen_at timestamptz,
 status text default 'active', authority numeric, risk numeric, traffic_estimate numeric, provider text, raw jsonb not null default '{}', normalized_source_url text, normalized_target_url text);
create table if not exists public.crm_seo_local_grid_runs(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, center_lat numeric, center_lng numeric, radius_m integer, grid_size integer, device text default 'mobile', status text default 'pending', provider text, results jsonb not null default '{}', captured_at timestamptz default now(), error_message text);
create table if not exists public.crm_seo_citation_records(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 directory text not null, listing_url text, business_name text, address text, phone text, status text default 'discovered', consistency_score numeric,
 competitor_present boolean default false, submitted_at timestamptz, verified_at timestamptz, raw jsonb not null default '{}');
create table if not exists public.crm_seo_review_sources(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_name text not null, listing_url text, review_count integer default 0, rating numeric, last_synced_at timestamptz, enabled boolean default true, raw jsonb not null default '{}', unique(site_id,source_name));
create table if not exists public.crm_seo_competitor_intelligence(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 competitor_domain text not null, estimated_traffic numeric, organic_keywords integer, top_pages jsonb not null default '[]', keyword_overlap jsonb not null default '[]', backlink_summary jsonb not null default '{}', content_inventory jsonb not null default '{}', sov numeric, observed_at timestamptz default now(), unique(site_id,competitor_domain));
create table if not exists public.crm_seo_content_scores(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 url text, keyword text, seo_score numeric, ai_search_score numeric, topical_coverage numeric, semantic_similarity numeric, entity_salience numeric,
 term_frequency jsonb not null default '{}', competitor_benchmark jsonb not null default '{}', recommendations jsonb not null default '[]', captured_at timestamptz default now());
create table if not exists public.crm_seo_deployment_targets_v2(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 target_type text not null, name text not null, endpoint text, credentials_ref text, enabled boolean default true, config jsonb not null default '{}', last_status text, last_checked_at timestamptz, unique(site_id,target_type,name));
create table if not exists public.crm_seo_workflow_nodes(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 workflow_id uuid references public.crm_seo_automation_workflows(id) on delete cascade, node_key text not null, node_type text not null, config jsonb not null default '{}', position jsonb not null default '{}', unique(workflow_id,node_key));
create table if not exists public.crm_seo_workflow_edges(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 workflow_id uuid references public.crm_seo_automation_workflows(id) on delete cascade, from_node text not null, to_node text not null, condition jsonb not null default '{}', unique(workflow_id,from_node,to_node));
create table if not exists public.crm_seo_provider_telemetry(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 provider text not null, operation text not null, latency_ms integer, status_code integer, success boolean, cost numeric, quota_remaining numeric, rate_limit_remaining numeric, request_id text, error_class text, metadata jsonb not null default '{}', created_at timestamptz default now());
create table if not exists public.crm_seo_alert_baselines(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 metric text not null, baseline numeric, stddev numeric, sample_count integer default 0, calculated_at timestamptz default now(), unique(site_id,metric));
create table if not exists public.crm_seo_agency_workspaces(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, name text not null, white_label_domain text, logo_url text, favicon_url text, email_sender jsonb not null default '{}', report_domain text, billing jsonb not null default '{}', settings jsonb not null default '{}', created_at timestamptz default now());
create table if not exists public.crm_seo_agency_clients(
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.crm_seo_agency_workspaces(id) on delete cascade, tenant_id uuid not null, name text not null, email text, status text default 'active', permissions jsonb not null default '{}', onboarding jsonb not null default '{}', created_at timestamptz default now());
create table if not exists public.crm_seo_client_tasks(
 id uuid primary key default gen_random_uuid(), client_id uuid references public.crm_seo_agency_clients(id) on delete cascade, site_id uuid references public.crm_seo_sites(id) on delete cascade, title text not null, status text default 'open', priority text default 'normal', assigned_to uuid, due_at timestamptz, metadata jsonb not null default '{}', created_at timestamptz default now());
create table if not exists public.crm_seo_revenue_attribution(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 keyword text, landing_page text, visitor_id text, lead_id uuid, customer_id uuid, booking_id uuid, transaction_id uuid, conversion_type text, revenue numeric default 0, currency text default 'INR', attribution_model text default 'last_non_direct', occurred_at timestamptz default now(), metadata jsonb not null default '{}');
create table if not exists public.crm_seo_market_certification(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 version text not null, category text not null, capability text not null, layer text not null, status text not null default 'not_started', evidence jsonb not null default '{}', verified_at timestamptz, unique(site_id,version,category,capability,layer));

-- SCO runtime.
create table if not exists public.crm_seo_sco_runs(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 status text not null default 'queued', source_summary jsonb not null default '{}', candidate_count integer not null default 0, created_at timestamptz not null default now(), completed_at timestamptz);
create table if not exists public.crm_seo_sco_opportunities(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 run_id uuid references public.crm_seo_sco_runs(id) on delete set null, keyword text not null, search_volume numeric, gap_score numeric, intent text, target_url text,
 has_target_page boolean not null default false, source text, opportunity_score numeric not null default 0, recommended_action text, recommended_slug text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(site_id,keyword));

-- Central SEO control plane: tasks, alerts, actions, operations, history.
create table if not exists public.crm_seo_tasks(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 issue_id uuid references public.crm_seo_issues(id) on delete set null, title text not null, description text, task_type text not null default 'seo_fix',
 status text not null default 'new', priority text not null default 'normal', assigned_to uuid, approval_required boolean not null default false,
 due_at timestamptz, source text, recommendation jsonb not null default '{}', action jsonb not null default '{}', verification jsonb not null default '{}',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), completed_at timestamptz);
create table if not exists public.crm_seo_alerts(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 alert_type text not null, severity text not null default 'warning', title text not null, message text not null, status text not null default 'open',
 source text, metric text, current_value numeric, baseline_value numeric, payload jsonb not null default '{}', first_detected_at timestamptz not null default now(), last_detected_at timestamptz not null default now(), acknowledged_at timestamptz, resolved_at timestamptz);
create table if not exists public.crm_seo_action_runs(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 task_id uuid references public.crm_seo_tasks(id) on delete set null, action_type text not null, status text not null default 'queued', approval_required boolean not null default false,
 started_at timestamptz, completed_at timestamptz, error_message text, input jsonb not null default '{}', output jsonb not null default '{}', created_at timestamptz not null default now());
create table if not exists public.crm_seo_operation_jobs(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 tenant_id uuid, job_type text not null, status text not null default 'queued', priority integer not null default 100, attempt integer not null default 0, max_attempts integer not null default 3,
 scheduled_at timestamptz not null default now(), started_at timestamptz, finished_at timestamptz, duration_ms integer, error_message text, payload jsonb not null default '{}', result jsonb not null default '{}', created_at timestamptz not null default now());
create table if not exists public.crm_seo_history(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 entity_type text not null, entity_id uuid, event_type text not null, before_data jsonb not null default '{}', after_data jsonb not null default '{}', actor_id uuid, created_at timestamptz not null default now());

alter table public.crm_seo_tasks add column if not exists tenant_id uuid;
alter table public.crm_seo_alerts add column if not exists tenant_id uuid;
alter table public.crm_seo_action_runs add column if not exists tenant_id uuid;

-- Tenant RLS for all new site-bound data.
do $$ declare t text; begin
 foreach t in array array['crm_seo_web_index_pages','crm_seo_web_index_links','crm_seo_keyword_index','crm_seo_serp_index','crm_seo_backlink_index','crm_seo_local_grid_runs','crm_seo_citation_records','crm_seo_review_sources','crm_seo_competitor_intelligence','crm_seo_content_scores','crm_seo_deployment_targets_v2','crm_seo_workflow_nodes','crm_seo_workflow_edges','crm_seo_provider_telemetry','crm_seo_alert_baselines','crm_seo_client_tasks','crm_seo_revenue_attribution','crm_seo_market_certification','crm_seo_sco_runs','crm_seo_sco_opportunities','crm_seo_tasks','crm_seo_alerts','crm_seo_action_runs','crm_seo_operation_jobs','crm_seo_history'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('drop policy if exists tenant_access on public.%I',t);
  execute format('create policy tenant_access on public.%I for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)))',t);
 end loop;
end $$;
alter table public.crm_seo_agency_workspaces enable row level security;
drop policy if exists tenant_access on public.crm_seo_agency_workspaces;
create policy tenant_access on public.crm_seo_agency_workspaces for all to authenticated using (public.anaira_tenant_access(tenant_id)) with check (public.anaira_tenant_access(tenant_id));
alter table public.crm_seo_agency_clients enable row level security;
drop policy if exists tenant_access on public.crm_seo_agency_clients;
create policy tenant_access on public.crm_seo_agency_clients for all to authenticated using (public.anaira_tenant_access(tenant_id)) with check (public.anaira_tenant_access(tenant_id));

create unique index if not exists crm_seo_backlink_identity_idx on public.crm_seo_backlink_index(site_id,normalized_source_url,normalized_target_url);
create unique index if not exists crm_seo_web_links_identity on public.crm_seo_web_index_links(site_id,source_url,target_url,anchor_text);
create index if not exists crm_seo_keyword_volume_idx on public.crm_seo_keyword_index(site_id,volume desc);
create index if not exists crm_seo_serp_domain_idx on public.crm_seo_serp_index(site_id,domain,captured_at desc);
create index if not exists crm_seo_tasks_status_idx on public.crm_seo_tasks(site_id,status,priority,created_at desc);
create index if not exists crm_seo_alerts_status_idx on public.crm_seo_alerts(site_id,status,severity,last_detected_at desc);
create index if not exists crm_seo_operations_status_idx on public.crm_seo_operation_jobs(status,priority,scheduled_at);
create index if not exists crm_seo_history_entity_idx on public.crm_seo_history(site_id,entity_type,entity_id,created_at desc);
