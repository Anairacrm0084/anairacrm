-- Anaira SEO Master A-to-Z completion migration
create extension if not exists pgcrypto;

alter table public.crm_seo_sites
  add column if not exists crawl_mode text not null default 'domain',
  add column if not exists include_subdomains boolean not null default false,
  add column if not exists include_paths jsonb not null default '[]'::jsonb,
  add column if not exists exclude_paths jsonb not null default '[]'::jsonb,
  add column if not exists url_params_mode text not null default 'ignore',
  add column if not exists custom_user_agent text,
  add column if not exists crawl_device text not null default 'desktop',
  add column if not exists crawl_delay_ms integer not null default 100,
  add column if not exists staging_mode boolean not null default false,
  add column if not exists archived boolean not null default false,
  add column if not exists verification_methods jsonb not null default '["dns_txt"]'::jsonb,
  add column if not exists brand_name text,
  add column if not exists report_logo_url text;

alter table public.crm_seo_pages
  add column if not exists http_status integer,
  add column if not exists http_status_text text,
  add column if not exists content_type text,
  add column if not exists response_time_ms integer,
  add column if not exists content_length integer,
  add column if not exists word_count integer,
  add column if not exists inlinks integer not null default 0,
  add column if not exists outlinks integer not null default 0,
  add column if not exists crawl_depth integer not null default 0,
  add column if not exists indexable boolean,
  add column if not exists language_code text,
  add column if not exists viewport_present boolean,
  add column if not exists mixed_content boolean,
  add column if not exists security_headers jsonb not null default '{}'::jsonb,
  add column if not exists image_count integer not null default 0,
  add column if not exists image_alt_missing integer not null default 0,
  add column if not exists script_bytes integer not null default 0,
  add column if not exists css_bytes integer not null default 0,
  add column if not exists content_hash text,
  add column if not exists headings_json jsonb not null default '[]'::jsonb,
  add column if not exists extracted_links jsonb not null default '[]'::jsonb,
  add column if not exists extracted_images jsonb not null default '[]'::jsonb,
  add column if not exists social_json jsonb not null default '{}'::jsonb,
  add column if not exists crawl_redirect_chain jsonb not null default '[]'::jsonb;

alter table public.crm_seo_audits
  add column if not exists crawl_config jsonb not null default '{}'::jsonb,
  add column if not exists comparison_audit_id uuid,
  add column if not exists crawl_mode text,
  add column if not exists max_pages integer,
  add column if not exists errors_count integer not null default 0,
  add column if not exists warnings_count integer not null default 0,
  add column if not exists notices_count integer not null default 0,
  add column if not exists discovered_urls integer not null default 0;

alter table public.crm_seo_issues
  add column if not exists code text,
  add column if not exists category text,
  add column if not exists impact text,
  add column if not exists affected_count integer not null default 1,
  add column if not exists fingerprint text,
  add column if not exists assigned_to uuid,
  add column if not exists ignored_until timestamptz,
  add column if not exists first_seen_at timestamptz not null default now(),
  add column if not exists last_seen_at timestamptz not null default now();
create index if not exists crm_seo_issues_site_status_idx on public.crm_seo_issues(site_id,status,severity,category);
create index if not exists crm_seo_issues_fingerprint_idx on public.crm_seo_issues(site_id,fingerprint);

alter table public.crm_seo_keywords
  add column if not exists difficulty numeric,
  add column if not exists traffic_potential numeric,
  add column if not exists cpc numeric,
  add column if not exists trend jsonb not null default '[]'::jsonb,
  add column if not exists parent_topic text,
  add column if not exists intent_confidence numeric,
  add column if not exists search_engine text not null default 'google',
  add column if not exists country text not null default 'IN',
  add column if not exists device text not null default 'desktop',
  add column if not exists group_name text,
  add column if not exists source text,
  add column if not exists notes text;

alter table public.crm_seo_competitors
  add column if not exists settings jsonb not null default '{}'::jsonb,
  add column if not exists last_collected_at timestamptz,
  add column if not exists health_status text not null default 'unknown';

create table if not exists public.crm_seo_serp_snapshots (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  keyword_id uuid references public.crm_seo_keywords(id) on delete cascade,
  keyword text not null,
  search_engine text not null default 'google',
  country text not null default 'IN',
  city text,
  device text not null default 'desktop',
  result_count integer not null default 0,
  results jsonb not null default '[]'::jsonb,
  features jsonb not null default '[]'::jsonb,
  captured_at timestamptz not null default now()
);
create index if not exists crm_seo_serp_snapshots_lookup on public.crm_seo_serp_snapshots(site_id,keyword,captured_at desc);

create table if not exists public.crm_seo_keyword_gap (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  competitor_id uuid references public.crm_seo_competitors(id) on delete cascade,
  keyword text not null,
  our_position numeric,
  competitor_position numeric,
  search_volume numeric,
  opportunity_score numeric,
  source text,
  captured_at timestamptz not null default now()
);
create index if not exists crm_seo_keyword_gap_lookup on public.crm_seo_keyword_gap(site_id,competitor_id,opportunity_score desc);

create table if not exists public.crm_seo_backlinks (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  source_url text not null,
  source_domain text,
  target_url text,
  anchor_text text,
  dofollow boolean,
  sponsored boolean,
  ugc boolean,
  first_seen_at timestamptz,
  last_seen_at timestamptz,
  source_rank numeric,
  domain_rank numeric,
  spam_score numeric,
  status text not null default 'live',
  raw jsonb not null default '{}'::jsonb,
  captured_at timestamptz not null default now()
);
create unique index if not exists crm_seo_backlinks_uq on public.crm_seo_backlinks(site_id,source_url,target_url,coalesce(anchor_text,''));
create index if not exists crm_seo_backlinks_site_idx on public.crm_seo_backlinks(site_id,captured_at desc);

create table if not exists public.crm_seo_backlink_domains (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  domain text not null,
  backlinks integer not null default 0,
  dofollow integer not null default 0,
  nofollow integer not null default 0,
  domain_rank numeric,
  spam_score numeric,
  first_seen_at timestamptz,
  last_seen_at timestamptz,
  status text not null default 'active',
  captured_at timestamptz not null default now(),
  unique(site_id,domain)
);

create table if not exists public.crm_seo_backlink_history (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  metric_date date not null,
  rank numeric,
  backlinks integer,
  new_backlinks integer,
  lost_backlinks integer,
  referring_domains integer,
  new_referring_domains integer,
  lost_referring_domains integer,
  captured_at timestamptz not null default now(),
  unique(site_id,metric_date)
);

create table if not exists public.crm_seo_local_locations (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  google_location_name text,
  account_id text,
  location_id text,
  place_id text,
  business_name text,
  address jsonb not null default '{}'::jsonb,
  phone text,
  website text,
  primary_category text,
  lat numeric,
  lng numeric,
  verification_state text,
  metadata jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(site_id,google_location_name)
);

create table if not exists public.crm_seo_local_metrics (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  location_id uuid references public.crm_seo_local_locations(id) on delete cascade,
  metric_date date not null,
  metric text not null,
  device text,
  value numeric not null default 0,
  source text not null default 'google_business_profile',
  raw jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create unique index if not exists crm_seo_local_metrics_uq on public.crm_seo_local_metrics(site_id,location_id,metric_date,metric,coalesce(device,''));

create table if not exists public.crm_seo_local_keywords (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  keyword text not null,
  latitude numeric,
  longitude numeric,
  radius_km numeric default 25,
  country text default 'IN',
  city text,
  position numeric,
  local_pack_position numeric,
  result_url text,
  source text not null default 'serpapi',
  captured_at timestamptz not null default now()
);
create index if not exists crm_seo_local_keywords_lookup on public.crm_seo_local_keywords(site_id,keyword,captured_at desc);

create table if not exists public.crm_seo_ai_visibility_prompts (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  prompt text not null,
  locale text default 'en-IN',
  provider text not null default 'openai',
  model text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_seo_ai_visibility_runs (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  prompt_id uuid references public.crm_seo_ai_visibility_prompts(id) on delete cascade,
  provider text not null,
  model text,
  answer text,
  brand_mentioned boolean,
  mention_count integer not null default 0,
  competitor_mentions jsonb not null default '[]'::jsonb,
  citations jsonb not null default '[]'::jsonb,
  sentiment text,
  confidence numeric,
  visibility_score numeric,
  status text not null default 'completed',
  error text,
  created_at timestamptz not null default now()
);
create index if not exists crm_seo_ai_visibility_runs_lookup on public.crm_seo_ai_visibility_runs(site_id,created_at desc);

create table if not exists public.crm_seo_report_configs (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  name text not null,
  cadence text not null default 'monthly',
  timezone text not null default 'Asia/Kolkata',
  recipients jsonb not null default '[]'::jsonb,
  sections jsonb not null default '[]'::jsonb,
  branding jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  next_run_at timestamptz not null default now(),
  last_run_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crm_seo_report_runs (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.crm_seo_report_configs(id) on delete cascade,
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  status text not null default 'queued',
  period_start date,
  period_end date,
  html text,
  csv_data text,
  recipients jsonb not null default '[]'::jsonb,
  sent_at timestamptz,
  error text,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_seo_page_changes (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  page_id uuid references public.crm_seo_pages(id) on delete cascade,
  audit_id uuid references public.crm_seo_audits(id) on delete set null,
  change_type text not null,
  before_data jsonb not null default '{}'::jsonb,
  after_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_seo_sitemap_submissions (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  sitemap_url text not null,
  provider text not null default 'google_search_console',
  status text not null default 'submitted',
  response jsonb not null default '{}'::jsonb,
  submitted_at timestamptz not null default now()
);

create table if not exists public.crm_seo_robots_versions (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  content text not null,
  source text not null default 'anaira',
  version_no integer not null default 1,
  active boolean not null default false,
  created_by uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_seo_provider_health (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
  provider text not null,
  status text not null default 'unknown',
  checked_at timestamptz not null default now(),
  latency_ms integer,
  last_error text,
  metadata jsonb not null default '{}'::jsonb,
  unique(site_id,provider)
);

-- Tenant-aware RLS for all child SEO tables.
do $$ declare t text; begin
  foreach t in array array[
    'crm_seo_serp_snapshots','crm_seo_keyword_gap','crm_seo_backlinks','crm_seo_backlink_domains','crm_seo_backlink_history',
    'crm_seo_local_locations','crm_seo_local_metrics','crm_seo_local_keywords','crm_seo_ai_visibility_prompts','crm_seo_ai_visibility_runs',
    'crm_seo_report_configs','crm_seo_report_runs','crm_seo_page_changes','crm_seo_sitemap_submissions','crm_seo_robots_versions','crm_seo_provider_health'
  ] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('drop policy if exists tenant_access on public.%I',t);
    execute format('create policy tenant_access on public.%I for all to authenticated using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id))) with check (exists(select 1 from public.crm_seo_sites s where s.id=site_id and public.anaira_tenant_access(s.tenant_id)))',t);
  end loop;
end $$;

-- Reports and provider-health indices.
create index if not exists crm_seo_report_configs_due_idx on public.crm_seo_report_configs(enabled,next_run_at);
create index if not exists crm_seo_report_runs_site_idx on public.crm_seo_report_runs(site_id,created_at desc);

