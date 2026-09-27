-- Phase 91 security follow-up.
revoke all on function public.anaira_current_is_business_admin() from anon;
grant execute on function public.anaira_current_is_business_admin() to authenticated;
revoke all on function public.anaira_guard_platform_owned_listing_fields() from anon, authenticated;
revoke all on function public.anaira_guard_platform_store_membership_fields() from anon, authenticated;
revoke all on function public.anaira_guard_plugin_activation() from anon, authenticated;

alter table public.hms_booking_payment_submissions enable row level security;
drop policy if exists "hms booking payment submissions tenant access" on public.hms_booking_payment_submissions;
create policy "hms booking payment submissions tenant access" on public.hms_booking_payment_submissions for select to authenticated using (restaurant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy "hms booking payment submissions tenant insert" on public.hms_booking_payment_submissions for insert to authenticated with check (restaurant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy "hms booking payment submissions business admin update" on public.hms_booking_payment_submissions for update to authenticated using (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin())) with check (public.anaira_current_is_super_admin() or (restaurant_id = public.anaira_current_restaurant_id() and public.anaira_current_is_business_admin()));
