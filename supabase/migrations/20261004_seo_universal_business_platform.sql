-- Universal SEO profile: business-type and website-platform agnostic.
alter table if exists public.crm_seo_sites add column if not exists business_vertical text not null default 'other';
alter table if exists public.crm_seo_sites add column if not exists platform_type text not null default 'custom';
alter table if exists public.crm_seo_sites add column if not exists seo_profile jsonb not null default '{}'::jsonb;
create index if not exists crm_seo_sites_business_vertical_idx on public.crm_seo_sites(business_vertical);
create index if not exists crm_seo_sites_platform_type_idx on public.crm_seo_sites(platform_type);
comment on column public.crm_seo_sites.business_vertical is 'Universal SEO business category; not limited to hospitality or restaurants.';
comment on column public.crm_seo_sites.platform_type is 'Website/application platform such as WordPress, Shopify, Next.js, Webflow or custom.';
comment on column public.crm_seo_sites.seo_profile is 'Vertical-neutral SEO strategy, goals, entities and service-area configuration.';
