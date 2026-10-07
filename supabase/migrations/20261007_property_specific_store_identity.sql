-- ANAIRA V18: PROPERTY-SPECIFIC STORE IDENTITY
-- Keeps the two existing platform stores as Super Admin templates/control records.
-- Every tenant/property gets its own real store row and membership.

alter table public.anaira_platform_stores
  add column if not exists restaurant_id uuid references public.restaurants(id) on delete cascade,
  add column if not exists is_platform_store boolean not null default false,
  add column if not exists parent_platform_store_id uuid references public.anaira_platform_stores(id) on delete set null,
  add column if not exists hospitality_type text;

-- Existing global Hotel/Restaurant rows remain platform stores.
update public.anaira_platform_stores
set is_platform_store=true, restaurant_id=null
where restaurant_id is null and store_type in ('hotel','restaurant');

create unique index if not exists anaira_property_store_type_uq
  on public.anaira_platform_stores(restaurant_id, store_type)
  where restaurant_id is not null;

create index if not exists anaira_platform_stores_property_idx
  on public.anaira_platform_stores(restaurant_id, store_type, enabled, published);

-- Resolve or create the exact store for one property.
create or replace function public.anaira_ensure_property_store(
  p_restaurant_id uuid,
  p_store_type text,
  p_hospitality_type text default null
) returns uuid
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  v_store uuid;
  v_parent uuid;
  v_name text;
  v_slug text;
begin
  if p_restaurant_id is null then raise exception 'restaurant_id is required'; end if;
  if p_store_type not in ('hotel','restaurant') then raise exception 'invalid store_type'; end if;

  if not (public.anaira_current_is_super_admin() or p_restaurant_id = public.anaira_current_restaurant_id()) then
    raise exception 'not authorized for this property';
  end if;

  select id into v_store
  from public.anaira_platform_stores
  where restaurant_id=p_restaurant_id and store_type=p_store_type
  limit 1;
  if v_store is not null then
    return v_store;
  end if;

  select id into v_parent
  from public.anaira_platform_stores
  where restaurant_id is null and is_platform_store=true and store_type=p_store_type
  order by created_at nulls first, id
  limit 1;

  select coalesce(name,'Property') into v_name from public.restaurants where id=p_restaurant_id;
  if v_name is null then raise exception 'property not found'; end if;
  v_slug := lower(regexp_replace(coalesce(v_name,'property') || '-' || replace(p_restaurant_id::text,'-',''), '[^a-zA-Z0-9]+', '-', 'g'));

  begin
    insert into public.anaira_platform_stores
      (store_name, store_type, slug, restaurant_id, is_platform_store, parent_platform_store_id,
       hospitality_type, enabled, published, builder_mode, public_path, settings, created_at, updated_at)
    values
      (v_name || case when p_store_type='hotel' then ' Hotel Store' else ' Restaurant Store' end,
       p_store_type, v_slug, p_restaurant_id, false, v_parent, p_hospitality_type,
       true, false, 'admin_builder', '/store/' || v_slug, '{}'::jsonb, now(), now())
    returning id into v_store;
  exception when unique_violation then
    select id into v_store
    from public.anaira_platform_stores
    where restaurant_id=p_restaurant_id and store_type=p_store_type
    limit 1;
    if v_store is null then raise; end if;
  end;

  insert into public.anaira_store_memberships
    (store_id, restaurant_id, enabled, sort_order, listing_override, catalog_source,
     manual_catalog_enabled, store_config, image_config, sync_status)
  values
    (v_store, p_restaurant_id, true, 0, '{}'::jsonb,
     case when p_store_type='hotel' then 'anaira_hms' else 'anaira_pos' end,
     false, '{}'::jsonb, '{}'::jsonb, 'not_configured')
  on conflict (store_id, restaurant_id) do update
    set enabled=true;

  insert into public.anaira_store_settings
    (restaurant_id, store_id, store_type, published)
  values (p_restaurant_id, v_store, p_store_type, false)
  on conflict (store_id, restaurant_id) do nothing;

  return v_store;
end;
$$;

revoke all on function public.anaira_ensure_property_store(uuid,text,text) from public;
grant execute on function public.anaira_ensure_property_store(uuid,text,text) to authenticated;

-- Backfill every existing tenant membership onto its own store identity.
do $$
declare
  r record;
  v_store uuid;
  v_type text;
begin
  for r in
    select distinct m.restaurant_id, s.store_type
    from public.anaira_store_memberships m
    join public.anaira_platform_stores s on s.id=m.store_id
    where m.restaurant_id is not null
  loop
    select coalesce(r.hospitality_type, rs.hospitality_type, 'hotel') into v_type
    from public.restaurants rs where rs.id=r.restaurant_id;
    if r.store_type='restaurant' then v_type := null; end if;

    select id into v_store
    from public.anaira_platform_stores
    where restaurant_id=r.restaurant_id and store_type=r.store_type
    limit 1;

    if v_store is null then
      select public.anaira_ensure_property_store(r.restaurant_id,r.store_type,v_type) into v_store;
    end if;

    -- Move existing presentation/configuration rows from the global template
    -- to the newly-created property store without losing their IDs/content.
    update public.anaira_store_settings
      set store_id=v_store, updated_at=now()
    where restaurant_id=r.restaurant_id
      and store_id in (select id from public.anaira_platform_stores where is_platform_store=true and restaurant_id is null and store_type=r.store_type);

    update public.anaira_store_categories
      set store_id=v_store, updated_at=now()
    where restaurant_id=r.restaurant_id
      and store_id in (select id from public.anaira_platform_stores where is_platform_store=true and restaurant_id is null and store_type=r.store_type);

    update public.anaira_store_offers
      set store_id=v_store, updated_at=now()
    where restaurant_id=r.restaurant_id
      and store_id in (select id from public.anaira_platform_stores where is_platform_store=true and restaurant_id is null and store_type=r.store_type);

    update public.anaira_store_banners
      set store_id=v_store, updated_at=now()
    where restaurant_id=r.restaurant_id
      and store_id in (select id from public.anaira_platform_stores where is_platform_store=true and restaurant_id is null and store_type=r.store_type);

    update public.anaira_marketplace_featured_items
      set store_id=v_store, updated_at=now()
    where restaurant_id=r.restaurant_id
      and store_id in (select id from public.anaira_platform_stores where is_platform_store=true and restaurant_id is null and store_type=r.store_type);

    update public.anaira_store_memberships
      set store_id=v_store
    where restaurant_id=r.restaurant_id
      and store_id in (select id from public.anaira_platform_stores where is_platform_store=true and restaurant_id is null and store_type=r.store_type);
  end loop;
end $$;

-- Public store reads must resolve the tenant store, never the global platform template.
drop policy if exists anaira_store_memberships_public_read on public.anaira_store_memberships;
create policy anaira_store_memberships_public_read on public.anaira_store_memberships
for select to public
using (
  enabled=true and exists(
    select 1 from public.anaira_platform_stores s
    where s.id=anaira_store_memberships.store_id
      and s.restaurant_id=anaira_store_memberships.restaurant_id
      and s.is_platform_store=false
      and s.enabled=true and s.published=true
  )
);


drop policy if exists anaira_store_banners_public on public.anaira_store_banners;
create policy anaira_store_banners_public on public.anaira_store_banners for select to public
using (active and exists(select 1 from public.anaira_platform_stores s where s.id=store_id and s.restaurant_id=restaurant_id and s.is_platform_store=false and s.store_type='restaurant' and s.enabled=true and s.published=true));

drop policy if exists anaira_featured_items_public on public.anaira_marketplace_featured_items;
create policy anaira_featured_items_public on public.anaira_marketplace_featured_items for select to public
using (active and exists(select 1 from public.anaira_platform_stores s where s.id=store_id and s.restaurant_id=restaurant_id and s.is_platform_store=false and s.store_type='restaurant' and s.enabled=true and s.published=true));
