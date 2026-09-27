-- Phase 91: Super Admin / Business Admin permission-scope lock.
-- Applied to live Supabase project bhptqdoteucuymmdzsmg.
-- Keep this migration synchronized with the live migration history.

create or replace function public.anaira_current_is_business_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and (p.role in ('admin','business_admin') or p.is_super_admin = true)
  ) or exists (
    select 1 from public.anaira_user_profiles up
    where up.user_id = auth.uid() and up.profile_key = 'business_admin'
  );
$$;
revoke all on function public.anaira_current_is_business_admin() from public;
grant execute on function public.anaira_current_is_business_admin() to authenticated;

drop policy if exists crm_booking_transactions_tenant_select on public.crm_booking_transactions;
create policy crm_booking_transactions_tenant_select on public.crm_booking_transactions for select to authenticated using (tenant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

drop policy if exists "hms_settings_tenant_write" on public.hms_settings;
drop policy if exists "hms_settings_tenant_access" on public.hms_settings;
create policy "hms_settings_tenant_access" on public.hms_settings for select to authenticated using (restaurant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy "hms_settings_tenant_write" on public.hms_settings for insert to authenticated with check (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));
create policy "hms_settings_tenant_update" on public.hms_settings for update to authenticated using (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin())) with check (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));
create policy "hms_settings_tenant_delete" on public.hms_settings for delete to authenticated using (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));

drop policy if exists "user permissions tenant access" on public.anaira_user_permissions;
create policy "user permissions tenant select" on public.anaira_user_permissions for select to authenticated using (public.anaira_can_access_tenant(restaurant_id));
create policy "user permissions business admin write" on public.anaira_user_permissions for insert to authenticated with check (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));
create policy "user permissions business admin update" on public.anaira_user_permissions for update to authenticated using (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin())) with check (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));
create policy "user permissions business admin delete" on public.anaira_user_permissions for delete to authenticated using (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));

create policy "marketplace orders tenant access" on public.anaira_marketplace_orders for select to authenticated using (customer_user_id = auth.uid() or restaurant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy "marketplace orders tenant update" on public.anaira_marketplace_orders for update to authenticated using (restaurant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

create or replace function public.anaira_guard_platform_owned_listing_fields() returns trigger language plpgsql security definer set search_path = public as $$ begin if not public.anaira_current_is_super_admin() and tg_op='UPDATE' then if new.approval_status is distinct from old.approval_status or new.commission_percent is distinct from old.commission_percent or new.published_at is distinct from old.published_at then raise exception 'Platform-owned marketplace fields require Super Admin'; end if; end if; return new; end; $$;
drop trigger if exists trg_guard_platform_owned_listing_fields on public.anaira_marketplace_listings;
create trigger trg_guard_platform_owned_listing_fields before insert or update on public.anaira_marketplace_listings for each row execute function public.anaira_guard_platform_owned_listing_fields();

create or replace function public.anaira_guard_platform_store_membership_fields() returns trigger language plpgsql security definer set search_path = public as $$ begin if not public.anaira_current_is_super_admin() and tg_op='UPDATE' then if new.featured is distinct from old.featured or new.sort_order is distinct from old.sort_order then raise exception 'Platform-owned store fields require Super Admin'; end if; end if; return new; end; $$;
drop trigger if exists trg_guard_platform_store_membership_fields on public.anaira_store_memberships;
create trigger trg_guard_platform_store_membership_fields before update on public.anaira_store_memberships for each row execute function public.anaira_guard_platform_store_membership_fields();

drop policy if exists "restaurant plugins tenant access" on public.restaurant_plugins;
create policy "restaurant plugins tenant access" on public.restaurant_plugins for select to authenticated using (restaurant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy "restaurant plugins tenant manage" on public.restaurant_plugins for insert to authenticated with check (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));
create policy "restaurant plugins tenant update" on public.restaurant_plugins for update to authenticated using (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin())) with check (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));
create policy "restaurant plugins tenant delete" on public.restaurant_plugins for delete to authenticated using (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));

create or replace function public.anaira_guard_plugin_activation() returns trigger language plpgsql security definer set search_path = public as $$ begin if not public.anaira_current_is_super_admin() and tg_op='UPDATE' then if new.enabled is distinct from old.enabled or new.activated_by is distinct from old.activated_by or new.activated_at is distinct from old.activated_at or new.disabled_at is distinct from old.disabled_at then raise exception 'Plugin activation state requires Super Admin'; end if; elsif not public.anaira_current_is_super_admin() and tg_op='INSERT' then new.enabled:=false; new.activated_by:=null; new.activated_at:=null; new.disabled_at:=null; end if; return new; end; $$;
drop trigger if exists trg_guard_plugin_activation on public.restaurant_plugins;
create trigger trg_guard_plugin_activation before insert or update on public.restaurant_plugins for each row execute function public.anaira_guard_plugin_activation();
