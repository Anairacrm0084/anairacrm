-- Property Store Domains + verified host resolution.
-- Additive only: preserves all existing properties, stores, bookings and inventory.

create table if not exists public.anaira_property_store_domains (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.anaira_platform_stores(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  domain text not null,
  domain_type text not null default 'custom',
  verification_method text not null default 'dns_txt',
  verification_token text not null,
  verification_status text not null default 'pending',
  domain_status text not null default 'pending',
  cname_target text,
  is_primary boolean not null default false,
  verified_at timestamptz,
  activated_at timestamptz,
  last_checked_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ana_prop_store_domain_type_chk check (domain_type in ('anaira_subdomain','custom')),
  constraint ana_prop_store_domain_method_chk check (verification_method in ('managed_subdomain','dns_txt')),
  constraint ana_prop_store_domain_verification_chk check (verification_status in ('pending','verified','failed')),
  constraint ana_prop_store_domain_status_chk check (domain_status in ('pending','active','disabled')),
  constraint ana_prop_store_domain_format_chk check (
    domain = lower(domain)
    and char_length(domain) between 4 and 253
    and domain ~ '^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$'
  )
);

create unique index if not exists ana_prop_store_domains_domain_uq
  on public.anaira_property_store_domains(domain);
create unique index if not exists ana_prop_store_domains_one_primary_uq
  on public.anaira_property_store_domains(store_id) where is_primary=true and domain_status='active';
create index if not exists ana_prop_store_domains_property_idx
  on public.anaira_property_store_domains(restaurant_id,domain_status,verification_status);
create index if not exists ana_prop_store_domains_store_idx
  on public.anaira_property_store_domains(store_id,created_at desc);

alter table public.anaira_property_store_domains enable row level security;
revoke all on public.anaira_property_store_domains from public,anon;
grant select,insert,update,delete on public.anaira_property_store_domains to authenticated;
grant all on public.anaira_property_store_domains to service_role;

drop policy if exists ana_prop_store_domains_tenant_read on public.anaira_property_store_domains;
create policy ana_prop_store_domains_tenant_read
  on public.anaira_property_store_domains for select to authenticated
  using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

drop policy if exists ana_prop_store_domains_tenant_insert on public.anaira_property_store_domains;
create policy ana_prop_store_domains_tenant_insert
  on public.anaira_property_store_domains for insert to authenticated
  with check (
    (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
    and exists (select 1 from public.anaira_platform_stores s
      where s.id=anaira_property_store_domains.store_id and s.restaurant_id=anaira_property_store_domains.restaurant_id
        and s.is_platform_store=false and s.store_type='hotel')
  );

drop policy if exists ana_prop_store_domains_tenant_update on public.anaira_property_store_domains;
create policy ana_prop_store_domains_tenant_update
  on public.anaira_property_store_domains for update to authenticated
  using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
  with check (
    (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
    and exists (select 1 from public.anaira_platform_stores s
      where s.id=anaira_property_store_domains.store_id and s.restaurant_id=anaira_property_store_domains.restaurant_id
        and s.is_platform_store=false and s.store_type='hotel')
  );

drop policy if exists ana_prop_store_domains_tenant_delete on public.anaira_property_store_domains;
create policy ana_prop_store_domains_tenant_delete
  on public.anaira_property_store_domains for delete to authenticated
  using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

-- This public resolver intentionally returns only public routing metadata.
-- It never exposes verification tokens, tenant configuration or credentials.
create or replace function public.anaira_resolve_property_store_domain(p_domain text)
returns table (
  restaurant_id uuid,
  hospitality_type text,
  store_slug text,
  store_name text,
  route_path text
)
language sql
stable
security definer
set search_path=''
as $$
  select r.id,
         coalesce(nullif(lower(r.hospitality_type),''),'hotel'),
         s.slug,
         s.store_name,
         case
           when coalesce(nullif(lower(r.hospitality_type),''),'hotel') in ('homestay','guest_house','cottage')
             then '/stay/' || coalesce(nullif(lower(r.hospitality_type),''),'homestay') || '/' || r.id::text
           else '/property/' || r.id::text || '?stay_type=' || coalesce(nullif(lower(r.hospitality_type),''),'hotel')
         end
  from public.anaira_property_store_domains d
  join public.anaira_platform_stores s on s.id=d.store_id and s.restaurant_id=d.restaurant_id
  join public.restaurants r on r.id=d.restaurant_id
  join public.anaira_store_memberships m on m.store_id=s.id and m.restaurant_id=s.restaurant_id
  left join public.anaira_store_settings ss on ss.store_id=s.id and ss.restaurant_id=s.restaurant_id
  where lower(trim(coalesce(p_domain,'')))=d.domain
    and d.domain_status='active'
    and d.verification_status='verified'
    and s.is_platform_store=false
    and s.store_type='hotel'
    and s.enabled=true
    and m.enabled=true
    and r.status='active'
    and (s.published=true or coalesce(ss.published,false)=true)
  limit 1;
$$;
revoke all on function public.anaira_resolve_property_store_domain(text) from public;
grant execute on function public.anaira_resolve_property_store_domain(text) to anon,authenticated;

comment on table public.anaira_property_store_domains is
  'Verified custom domains and Anaira-managed subdomains for independent hospitality property stores. DNS/SSL provisioning is external to this table.';
comment on function public.anaira_resolve_property_store_domain(text) is
  'Public-safe host resolver. Returns only the published property store route; never returns verification tokens.';
