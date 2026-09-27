-- IMPORTANT:
-- This migration intentionally does NOT guess your existing Anaira tenant/profile schema.
-- Before production, replace the broad authenticated policies from the scaffold with
-- tenant-scoped policies based on your actual profiles/restaurant/property ownership.
--
-- No DROP/TRUNCATE/DELETE migration is included.
-- This file exists as the explicit hardening checkpoint before production.
create table if not exists public.crm_security_config (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid unique,
  production_rls_verified boolean default false,
  verified_by uuid,
  verified_at timestamptz,
  notes text,
  created_at timestamptz default now()
);
alter table public.crm_security_config enable row level security;
create policy "security_config_auth" on public.crm_security_config for all to authenticated using (true) with check (true);
