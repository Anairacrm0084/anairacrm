-- V14: public restaurant store resolution is scoped by the published Restaurant platform store.
-- The existing ana­ira_store_memberships_public_read policy already exposes only enabled memberships
-- belonging to enabled/published platform stores. This migration documents/repairs the policy idempotently.
drop policy if exists anaira_store_memberships_public_read on public.anaira_store_memberships;
create policy anaira_store_memberships_public_read
on public.anaira_store_memberships
for select to public
using (
  enabled = true
  and exists (
    select 1
    from public.anaira_platform_stores s
    where s.id = anaira_store_memberships.store_id
      and s.store_type = 'restaurant'
      and s.enabled = true
      and s.published = true
  )
);
