-- Store Builder resolver + tenant-scoped visibility/write policies.
-- Draft stores remain editable in the admin builder; publish state controls public visibility only.
create or replace function public.anaira_store_builder_resolve(
  p_restaurant_id uuid, p_store_type text, p_hospitality_type text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_store public.anaira_platform_stores%rowtype; v_membership public.anaira_store_memberships%rowtype; v_settings public.anaira_store_settings%rowtype; v_store_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_restaurant_id is null then raise exception 'restaurant_id is required'; end if;
  if p_store_type not in ('hotel','restaurant') then raise exception 'Invalid store type'; end if;
  if not public.anaira_current_is_super_admin() and p_restaurant_id is distinct from public.anaira_current_restaurant_id() then raise exception 'Not authorized for this property'; end if;
  select * into v_store from public.anaira_platform_stores s where s.restaurant_id=p_restaurant_id and s.store_type=p_store_type and s.is_platform_store=false order by s.created_at nulls first,s.id limit 1;
  if v_store.id is null then
    v_store_id:=public.anaira_ensure_property_store(p_restaurant_id,p_store_type,p_hospitality_type);
    select * into v_store from public.anaira_platform_stores where id=v_store_id;
  end if;
  if v_store.id is null then raise exception 'Property store could not be provisioned'; end if;
  select * into v_membership from public.anaira_store_memberships where store_id=v_store.id and restaurant_id=p_restaurant_id limit 1;
  if v_membership.id is null then
    insert into public.anaira_store_memberships(store_id,restaurant_id,enabled,sort_order,listing_override,catalog_source,manual_catalog_enabled,store_config,image_config,sync_status)
    values(v_store.id,p_restaurant_id,true,0,'{}'::jsonb,case when p_store_type='hotel' then 'anaira_hms' else 'anaira_pos' end,false,'{}'::jsonb,'{}'::jsonb,'not_configured') on conflict(store_id,restaurant_id) do nothing;
    select * into v_membership from public.anaira_store_memberships where store_id=v_store.id and restaurant_id=p_restaurant_id limit 1;
  end if;
  select * into v_settings from public.anaira_store_settings where store_id=v_store.id and restaurant_id=p_restaurant_id limit 1;
  if v_settings.store_id is null then
    insert into public.anaira_store_settings(restaurant_id,store_id,store_type,published) values(p_restaurant_id,v_store.id,p_store_type,false) on conflict(store_id,restaurant_id) do nothing;
    select * into v_settings from public.anaira_store_settings where store_id=v_store.id and restaurant_id=p_restaurant_id limit 1;
  end if;
  return jsonb_build_object('store',to_jsonb(v_store),'membership',case when v_membership.id is null then null else to_jsonb(v_membership) end,'settings',case when v_settings.store_id is null then null else to_jsonb(v_settings) end);
end; $$;
revoke all on function public.anaira_store_builder_resolve(uuid,text,text) from public,anon;
grant execute on function public.anaira_store_builder_resolve(uuid,text,text) to authenticated;

drop policy if exists anaira_platform_stores_tenant_store_select on public.anaira_platform_stores;
create policy anaira_platform_stores_tenant_store_select on public.anaira_platform_stores for select to authenticated
using (is_platform_store=true or restaurant_id=(select p.restaurant_id from public.profiles p where p.id=auth.uid()) or public.anaira_current_is_super_admin());
drop policy if exists anaira_store_memberships_tenant_select on public.anaira_store_memberships;
create policy anaira_store_memberships_tenant_select on public.anaira_store_memberships for select to authenticated
using (restaurant_id=(select p.restaurant_id from public.profiles p where p.id=auth.uid()) or public.anaira_current_is_super_admin());
drop policy if exists anaira_store_memberships_tenant_write on public.anaira_store_memberships;
create policy anaira_store_memberships_tenant_write on public.anaira_store_memberships for all to authenticated
using (restaurant_id=(select p.restaurant_id from public.profiles p where p.id=auth.uid()) or public.anaira_current_is_super_admin())
with check (restaurant_id=(select p.restaurant_id from public.profiles p where p.id=auth.uid()) or public.anaira_current_is_super_admin());
drop policy if exists anaira_store_settings_tenant_write on public.anaira_store_settings;
create policy anaira_store_settings_tenant_write on public.anaira_store_settings for all to authenticated
using (restaurant_id=(select p.restaurant_id from public.profiles p where p.id=auth.uid()) or public.anaira_current_is_super_admin())
with check (restaurant_id=(select p.restaurant_id from public.profiles p where p.id=auth.uid()) or public.anaira_current_is_super_admin());
notify pgrst,'reload schema';
