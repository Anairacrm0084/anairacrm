-- Phase 32: Market-parity SEO intelligence/data/control plane.
-- Provider-backed tables are intentionally source-agnostic so Anaira can operate
-- with first-party indexes or external providers without changing the UI contract.
create extension if not exists pgcrypto;

create table if not exists public.crm_seo_web_index_pages(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 url text not null, normalized_url text not null, status_code integer, content_type text, title text, content_hash text,
 word_count integer default 0, crawl_depth integer default 0, first_seen_at timestamptz default now(), last_seen_at timestamptz default now(),
 last_crawled_at timestamptz default now(), headers jsonb not null default '{}', extracted jsonb not null default '{}', snapshot jsonb not null default '{}',
 unique(site_id,normalized_url)
);
create index if not exists crm_seo_web_index_pages_site_idx on public.crm_seo_web_index_pages(site_id,last_crawled_at desc);

create table if not exists public.crm_seo_web_index_links(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_url text not null, target_url text not null, anchor_text text, rel text, first_seen_at timestamptz default now(), last_seen_at timestamptz default now(),
 attributes jsonb not null default '{}'
);

create table if not exists public.crm_seo_keyword_index(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, locale text default 'en-IN', country text, city text, device text default 'desktop', language text,
 volume numeric, difficulty numeric, cpc numeric, intent text, trend jsonb not null default '{}', seasonality jsonb not null default '{}',
 questions jsonb not null default '[]', related jsonb not null default '[]', cluster text, source text, source_ref text, observed_at timestamptz default now(),
 unique(site_id,keyword,locale,device)
);
create index if not exists crm_seo_keyword_index_lookup on public.crm_seo_keyword_index(site_id,keyword);

create table if not exists public.crm_seo_serp_index(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, engine text not null, locale text, device text, captured_at timestamptz default now(),
 position integer, url text, domain text, title text, snippet text, feature text, citation_url text, provider text, raw jsonb not null default '{}'
);
create index if not exists crm_seo_serp_index_lookup on public.crm_seo_serp_index(site_id,keyword,captured_at desc);

create table if not exists public.crm_seo_backlink_index(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_url text not null, target_url text not null, source_domain text, anchor text, rel text, first_seen_at timestamptz, last_seen_at timestamptz,
 status text default 'active', authority numeric, risk numeric, traffic_estimate numeric, provider text, raw jsonb not null default '{}'
);
create index if not exists crm_seo_backlink_index_site_idx on public.crm_seo_backlink_index(site_id,last_seen_at desc);

create table if not exists public.crm_seo_local_grid_runs(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, center_lat numeric, center_lng numeric, radius_m integer, grid_size integer, device text default 'mobile', status text default 'pending',
 provider text, results jsonb not null default '{}', captured_at timestamptz default now(), error_message text
);
create table if not exists public.crm_seo_citation_records(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 directory text not null, listing_url text, business_name text, address text, phone text, status text default 'discovered', consistency_score numeric,
 competitor_present boolean default false, submitted_at timestamptz, verified_at timestamptz, raw jsonb not null default '{}'
);
create table if not exists public.crm_seo_review_sources(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_name text not null, listing_url text, review_count integer default 0, rating numeric, last_synced_at timestamptz,
 enabled boolean default true, raw jsonb not null default '{}', unique(site_id,source_name)
);

create table if not exists public.crm_seo_competitor_intelligence(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 competitor_domain text not null, estimated_traffic numeric, organic_keywords integer, top_pages jsonb not null default '[]', keyword_overlap jsonb not null default '[]',
 backlink_summary jsonb not null default '{}', content_inventory jsonb not null default '{}', sov numeric, observed_at timestamptz default now(),
 unique(site_id,competitor_domain)
);

create table if not exists public.crm_seo_content_scores(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 url text, keyword text, seo_score numeric, ai_search_score numeric, topical_coverage numeric, semantic_similarity numeric, entity_salience numeric,
 term_frequency jsonb not null default '{}', competitor_benchmark jsonb not null default '{}', recommendations jsonb not null default '[]', captured_at timestamptz default now()
);

create table if not exists public.crm_seo_deployment_targets_v2(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 target_type text not null, name text not null, endpoint text, credentials_ref text, enabled boolean default true, config jsonb not null default '{}',
 last_status text, last_checked_at timestamptz, unique(site_id,target_type,name)
);

create table if not exists public.crm_seo_workflow_nodes(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 workflow_id uuid references public.crm_seo_automation_workflows(id) on delete cascade, node_key text not null, node_type text not null,
 config jsonb not null default '{}', position jsonb not null default '{}', unique(workflow_id,node_key)
);
create table if not exists public.crm_seo_workflow_edges(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade, workflow_id uuid references public.crm_seo_automation_workflows(id) on delete cascade,
 from_node text not null, to_node text not null, condition jsonb not null default '{}', unique(workflow_id,from_node,to_node)
);

create table if not exists public.crm_seo_provider_telemetry(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 provider text not null, operation text not null, latency_ms integer, status_code integer, success boolean, cost numeric, quota_remaining numeric,
 rate_limit_remaining numeric, request_id text, error_class text, metadata jsonb not null default '{}', created_at timestamptz default now()
);
create index if not exists crm_seo_provider_telemetry_idx on public.crm_seo_provider_telemetry(provider,created_at desc);

create table if not exists public.crm_seo_alert_baselines(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 metric text not null, baseline numeric, stddev numeric, sample_count integer default 0, calculated_at timestamptz default now(), unique(site_id,metric)
);

create table if not exists public.crm_seo_agency_workspaces(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, name text not null, white_label_domain text, logo_url text, favicon_url text,
 email_sender jsonb not null default '{}', report_domain text, billing jsonb not null default '{}', settings jsonb not null default '{}', created_at timestamptz default now()
);
create table if not exists public.crm_seo_agency_clients(
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.crm_seo_agency_workspaces(id) on delete cascade,
 tenant_id uuid not null, name text not null, email text, status text default 'active', permissions jsonb not null default '{}', onboarding jsonb not null default '{}', created_at timestamptz default now()
);
create table if not exists public.crm_seo_client_tasks(
 id uuid primary key default gen_random_uuid(), client_id uuid references public.crm_seo_agency_clients(id) on delete cascade,
 site_id uuid references public.crm_seo_sites(id) on delete cascade, title text not null, status text default 'open', priority text default 'normal', assigned_to uuid,
 due_at timestamptz, metadata jsonb not null default '{}', created_at timestamptz default now()
);

create table if not exists public.crm_seo_revenue_attribution(
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 keyword text, landing_page text, visitor_id text, lead_id uuid, customer_id uuid, booking_id uuid, transaction_id uuid,
 conversion_type text, revenue numeric default 0, currency text default 'INR', attribution_model text default 'last_non_direct', occurred_at timestamptz default now(), metadata jsonb not null default '{}'
);
create index if not exists crm_seo_revenue_attr_site_idx on public.crm_seo_revenue_attribution(site_id,occurred_at desc);

create table if not exists public.crm_seo_market_certification(
 id uuid primary key default gen_random_uuid(), site_id uuid references public.crm_seo_sites(id) on delete cascade,
 version text not null, category text not null, capability text not null, layer text not null, status text not null default 'not_started', evidence jsonb not null default '{}',
 verified_at timestamptz, unique(site_id,version,category,capability,layer)
);
create index if not exists crm_seo_market_certification_idx on public.crm_seo_market_certification(site_id,category,status);

-- Tenant RLS. Sites already carry the tenant boundary.
do $$ declare t text; begin
 foreach t in array array['crm_seo_web_index_pages','crm_seo_web_index_links','crm_seo_keyword_index','crm_seo_serp_index','crm_seo_backlink_index','crm_seo_local_grid_runs','crm_seo_citation_records','crm_seo_review_sources','crm_seo_competitor_intelligence','crm_seo_content_scores','crm_seo_deployment_targets_v2','crm_seo_workflow_nodes','crm_seo_workflow_edges','crm_seo_provider_telemetry','crm_seo_alert_baselines','crm_seo_client_tasks','crm_seo_revenue_attribution','crm_seo_market_certification'] loop
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

-- Phase 32.1 hardening: deterministic backlink identity and certification evidence.
alter table public.crm_seo_backlink_index add column if not exists normalized_source_url text;
alter table public.crm_seo_backlink_index add column if not exists normalized_target_url text;
update public.crm_seo_backlink_index set normalized_source_url=lower(trim(source_url)), normalized_target_url=lower(trim(target_url)) where normalized_source_url is null or normalized_target_url is null;
delete from public.crm_seo_backlink_index a using public.crm_seo_backlink_index b where a.site_id=b.site_id and a.normalized_source_url=b.normalized_source_url and a.normalized_target_url=b.normalized_target_url and a.id>b.id;
create unique index if not exists crm_seo_backlink_identity_idx on public.crm_seo_backlink_index(site_id,normalized_source_url,normalized_target_url);
create index if not exists crm_seo_keyword_index_volume_idx on public.crm_seo_keyword_index(site_id,volume desc);
create index if not exists crm_seo_serp_index_domain_idx on public.crm_seo_serp_index(site_id,domain,captured_at desc);
