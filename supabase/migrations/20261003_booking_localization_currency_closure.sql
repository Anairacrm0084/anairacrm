-- Anaira Booking Engine localization/currency closure.
-- Presentation currency is explicit; payment settlement remains provider/tenant controlled.
create table if not exists public.booking_localization_catalog (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  language_code text not null default 'en-IN',
  currency_code text not null default 'INR',
  enabled boolean not null default true,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id,language_code,currency_code)
);
create index if not exists idx_booking_localization_catalog_tenant on public.booking_localization_catalog(tenant_id,enabled);
alter table public.booking_localization_catalog enable row level security;
drop policy if exists booking_localization_catalog_tenant_select on public.booking_localization_catalog;
create policy booking_localization_catalog_tenant_select on public.booking_localization_catalog for select to authenticated using (public.anaira_can_access_tenant(tenant_id));
drop policy if exists booking_localization_catalog_tenant_write on public.booking_localization_catalog;
create policy booking_localization_catalog_tenant_write on public.booking_localization_catalog for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

create table if not exists public.booking_currency_rates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  base_currency text not null default 'INR',
  quote_currency text not null,
  rate numeric(20,10) not null check(rate>0),
  source text not null default 'manual',
  effective_at timestamptz not null default now(),
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(tenant_id,base_currency,quote_currency,effective_at)
);
create index if not exists idx_booking_currency_rates_lookup on public.booking_currency_rates(tenant_id,base_currency,quote_currency,effective_at desc);
alter table public.booking_currency_rates enable row level security;
drop policy if exists booking_currency_rates_tenant_select on public.booking_currency_rates;
create policy booking_currency_rates_tenant_select on public.booking_currency_rates for select to authenticated using (public.anaira_can_access_tenant(tenant_id));
drop policy if exists booking_currency_rates_tenant_write on public.booking_currency_rates;
create policy booking_currency_rates_tenant_write on public.booking_currency_rates for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_get_booking_currency_rate(p_tenant_id uuid,p_base_currency text,p_quote_currency text,p_at timestamptz default now())
returns numeric language sql stable security invoker set search_path=public,pg_temp as $$
 select case when upper(p_base_currency)=upper(p_quote_currency) then 1 else (
   select r.rate from public.booking_currency_rates r
   where r.tenant_id=p_tenant_id and upper(r.base_currency)=upper(p_base_currency) and upper(r.quote_currency)=upper(p_quote_currency)
     and r.effective_at<=p_at and (r.expires_at is null or r.expires_at>p_at)
   order by r.effective_at desc limit 1
 ) end;
$$;
revoke execute on function public.anaira_get_booking_currency_rate(uuid,text,text,timestamptz) from anon;
grant execute on function public.anaira_get_booking_currency_rate(uuid,text,text,timestamptz) to authenticated;
