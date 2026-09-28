create table if not exists public.anaira_seo_web_pages (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 url text not null, normalized_url text not null, canonical_url text, status_code integer, content_type text, title text,
 meta_description text, word_count integer default 0, content_hash text, first_seen_at timestamptz default now(), last_seen_at timestamptz default now(),
 last_crawled_at timestamptz, crawl_depth integer default 0, inlinks integer default 0, outlinks integer default 0,
 indexable boolean, render_mode text default 'http', http_headers jsonb not null default '{}'::jsonb, extracted jsonb not null default '{}'::jsonb,
 unique(site_id,normalized_url)
);
create index if not exists anaira_seo_web_pages_site_idx on public.anaira_seo_web_pages(site_id,last_crawled_at desc);

create table if not exists public.anaira_seo_web_links (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 source_url text not null, target_url text not null, anchor_text text, rel text, status_code integer, first_seen_at timestamptz default now(), last_seen_at timestamptz default now(),
 unique(site_id,source_url,target_url)
);
create index if not exists anaira_seo_web_links_target_idx on public.anaira_seo_web_links(site_id,target_url);

create table if not exists public.anaira_seo_serp_snapshots (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, location text default 'India', language text default 'en', device text default 'desktop', provider text not null,
 captured_at timestamptz default now(), position numeric, visibility numeric, share_of_voice numeric, features jsonb not null default '[]'::jsonb,
 competitors jsonb not null default '[]'::jsonb, results jsonb not null default '[]'::jsonb, raw_provider jsonb not null default '{}'::jsonb
);
create index if not exists anaira_seo_serp_kw_idx on public.anaira_seo_serp_snapshots(site_id,keyword,captured_at desc);

create table if not exists public.anaira_seo_backlink_snapshots (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 target_url text not null, source_url text not null, referring_domain text, anchor_text text, rel text, authority numeric,
 first_seen_at timestamptz, last_seen_at timestamptz default now(), state text default 'active', provider text, raw_provider jsonb not null default '{}'::jsonb,
 unique(site_id,source_url,target_url)
);
create index if not exists anaira_seo_backlinks_domain_idx on public.anaira_seo_backlink_snapshots(site_id,referring_domain);

create table if not exists public.anaira_seo_local_grid_runs (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 keyword text not null, center_lat numeric not null, center_lng numeric not null, radius_m integer default 5000, grid_size integer default 5,
 provider text, status text default 'queued', created_at timestamptz default now(), completed_at timestamptz,
 cells jsonb not null default '[]'::jsonb, summary jsonb not null default '{}'::jsonb, error text
);
create index if not exists anaira_seo_local_grid_site_idx on public.anaira_seo_local_grid_runs(site_id,created_at desc);

create table if not exists public.anaira_seo_geo_runs (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 provider text not null, prompt text not null, model text, status text default 'queued', captured_at timestamptz default now(),
 mentions jsonb not null default '[]'::jsonb, citations jsonb not null default '[]'::jsonb, competitors jsonb not null default '[]'::jsonb,
 visibility numeric, sentiment numeric, share_of_voice numeric, raw_response jsonb not null default '{}'::jsonb, error text
);
create index if not exists anaira_seo_geo_site_idx on public.anaira_seo_geo_runs(site_id,captured_at desc);

create table if not exists public.anaira_seo_attribution_events (
 id uuid primary key default gen_random_uuid(), site_id uuid not null references public.crm_seo_sites(id) on delete cascade,
 event_type text not null, anonymous_id text, customer_id uuid, session_id text, keyword text, landing_url text, lead_id uuid,
 booking_id uuid, revenue numeric default 0, currency text default 'INR', occurred_at timestamptz default now(), metadata jsonb not null default '{}'::jsonb,
 idempotency_key text, unique(site_id,idempotency_key)
);
create index if not exists anaira_seo_attr_site_time_idx on public.anaira_seo_attribution_events(site_id,occurred_at desc);

alter table public.anaira_seo_web_pages enable row level security;
alter table public.anaira_seo_web_links enable row level security;
alter table public.anaira_seo_serp_snapshots enable row level security;
alter table public.anaira_seo_backlink_snapshots enable row level security;
alter table public.anaira_seo_local_grid_runs enable row level security;
alter table public.anaira_seo_geo_runs enable row level security;
alter table public.anaira_seo_attribution_events enable row level security;

create policy anaira_seo_web_pages_tenant on public.anaira_seo_web_pages using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and s.tenant_id=auth.uid()));
create policy anaira_seo_web_links_tenant on public.anaira_seo_web_links using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and s.tenant_id=auth.uid()));
create policy anaira_seo_serp_tenant on public.anaira_seo_serp_snapshots using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and s.tenant_id=auth.uid()));
create policy anaira_seo_backlinks_tenant on public.anaira_seo_backlink_snapshots using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and s.tenant_id=auth.uid()));
create policy anaira_seo_local_grid_tenant on public.anaira_seo_local_grid_runs using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and s.tenant_id=auth.uid()));
create policy anaira_seo_geo_tenant on public.anaira_seo_geo_runs using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and s.tenant_id=auth.uid()));
create policy anaira_seo_attr_tenant on public.anaira_seo_attribution_events using (exists(select 1 from public.crm_seo_sites s where s.id=site_id and s.tenant_id=auth.uid()));
