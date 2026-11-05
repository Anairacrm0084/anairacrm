-- Restrict anonymous store-membership discovery to the matching, published
-- tenant store. Replaces the historical tautological store-owner predicate.
-- Idempotent and data-preserving.
drop policy if exists anaira_store_memberships_public_read
  on public.anaira_store_memberships;

create policy anaira_store_memberships_public_read
  on public.anaira_store_memberships
  for select
  to anon, authenticated
  using (
    enabled = true
    and exists (
      select 1
      from public.anaira_platform_stores s
      where s.id = anaira_store_memberships.store_id
        and s.restaurant_id = anaira_store_memberships.restaurant_id
        and s.is_platform_store = false
        and s.enabled = true
        and s.published = true
    )
  );
