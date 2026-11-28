-- Restore the membership audit timestamp used by Super Admin store editors.
-- Additive only: existing membership settings, links and listing data are preserved.
alter table public.anaira_store_memberships
  add column if not exists updated_at timestamptz not null default now();

update public.anaira_store_memberships
set updated_at = coalesce(updated_at, created_at, now())
where updated_at is null;

comment on column public.anaira_store_memberships.updated_at
  is 'Last update timestamp for store membership and listing configuration.';
