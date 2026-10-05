-- Booking Engine security closure: explicit tenant policies and public-RPC execution boundaries.
-- Public checkout RPCs remain intentionally executable by anon; internal helper RPCs do not.

create policy if not exists booking_ab_assignments_tenant on public.booking_ab_assignments
for all to authenticated
using (exists(select 1 from public.booking_ab_tests e where e.id=experiment_id and (e.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())))
with check (exists(select 1 from public.booking_ab_tests e where e.id=experiment_id and (e.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())));
create policy if not exists booking_ab_tests_tenant on public.booking_ab_tests
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy if not exists booking_chain_rate_controls_tenant on public.booking_chain_rate_controls
for all to authenticated using (property_id is null or property_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (property_id is null or property_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy if not exists booking_competitor_rate_sources_tenant on public.booking_competitor_rate_sources
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy if not exists booking_competitor_rates_tenant on public.booking_competitor_rates
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy if not exists booking_funnel_daily_tenant on public.booking_funnel_daily
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy if not exists booking_invoice_sequences_tenant on public.booking_invoice_sequences
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

revoke execute on function public.anaira_booking_member_context(uuid,uuid,uuid,numeric) from anon;
revoke execute on function public.anaira_booking_reconciliation_case(uuid,text,text,uuid,uuid,jsonb,jsonb) from anon;
revoke execute on function public.anaira_booking_rule_check(uuid,uuid,uuid,date,date) from anon;
revoke execute on function public.anaira_calculate_hotel_premium_quote(uuid,uuid,uuid,date,date,integer,integer,text,jsonb) from anon;
-- The v3 transaction is the sole public hotel checkout entry point; its internal helpers stay private.
revoke execute on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from anon;
grant execute on function public.anaira_start_verified_hotel_booking_transaction_v3(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid,uuid,text,text) to anon,authenticated;
