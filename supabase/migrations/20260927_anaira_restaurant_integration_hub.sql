create extension if not exists pgcrypto;
create or replace function public.anaira_tenant_access(p_tenant_id uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and (p.is_super_admin=true or p.restaurant_id=p_tenant_id)); $$;
revoke all on function public.anaira_tenant_access(uuid) from public;
grant execute on function public.anaira_tenant_access(uuid) to authenticated;
create table if not exists public.anaira_restaurant_connections (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null references public.restaurants(id) on delete cascade,
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 restaurant_api_base_url text not null,
 restaurant_api_key text not null,
 status text not null default 'disconnected' check(status in ('disconnected','connected','error','paused')),
 capabilities jsonb not null default '{"catalog":true,"availability":true,"orders":true,"payments":true,"delivery":true,"reservations":true,"inventory":true}'::jsonb,
 last_sync_at timestamptz,
 last_error text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(tenant_id,restaurant_id)
);
create table if not exists public.anaira_restaurant_sync_jobs (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null references public.restaurants(id) on delete cascade,
 connection_id uuid not null references public.anaira_restaurant_connections(id) on delete cascade,
 direction text not null,
 entity_type text not null,
 status text not null default 'pending' check(status in ('pending','processing','success','failed')),
 idempotency_key text,
 records_read integer not null default 0,
 records_written integer not null default 0,
 attempts integer not null default 0,
 error text,
 created_at timestamptz not null default now(),
 completed_at timestamptz,
 unique(connection_id,idempotency_key)
);
create index if not exists idx_anaira_restaurant_sync_due on public.anaira_restaurant_sync_jobs(status,created_at);
alter table public.anaira_restaurant_connections enable row level security;
alter table public.anaira_restaurant_sync_jobs enable row level security;
drop policy if exists anaira_restaurant_connections_tenant on public.anaira_restaurant_connections;
create policy anaira_restaurant_connections_tenant on public.anaira_restaurant_connections for all to authenticated using (tenant_id=restaurant_id and (public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id))) with check (tenant_id=restaurant_id and (public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id)));
drop policy if exists anaira_restaurant_sync_tenant on public.anaira_restaurant_sync_jobs;
create policy anaira_restaurant_sync_tenant on public.anaira_restaurant_sync_jobs for all to authenticated using (public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id)) with check (public.anaira_is_super_admin() or public.anaira_tenant_access(tenant_id));
