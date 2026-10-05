-- Final Booking Engine security closure.
-- Protected booking writes run server-side with service_role; public checkout no longer calls privileged RPCs directly.

create policy booking_direct_benefits_tenant_final on public.booking_direct_benefits
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_personalized_offers_tenant_final on public.booking_personalized_offers
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_corporate_rates_tenant_final on public.booking_corporate_rates
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_negotiated_rates_tenant_final on public.booking_negotiated_rates
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_restrictions_tenant_final on public.booking_restrictions
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_group_allocations_tenant_final on public.booking_group_allocations
for all to authenticated using (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())))
with check (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())));
create policy booking_group_folios_tenant_final on public.booking_group_folios
for all to authenticated using (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())))
with check (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())));
create policy booking_reconciliation_cases_tenant_final on public.booking_reconciliation_cases
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_revenue_daily_tenant_final on public.booking_revenue_daily
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_channel_reconciliation_tenant_final on public.booking_channel_reconciliation
for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

-- booking_invoice_sequences was already tenant protected by the prior closure migration.

-- Internal booking RPCs must never be directly callable by anon. The server-side booking route uses service_role.
revoke execute on function public.anaira_booking_member_context(uuid,uuid,uuid,numeric) from anon;
revoke execute on function public.anaira_booking_member_context(uuid,uuid,uuid,numeric) from public;
revoke execute on function public.anaira_booking_reconciliation_case(uuid,text,text,uuid,uuid,jsonb,jsonb) from anon;
revoke execute on function public.anaira_booking_reconciliation_case(uuid,text,text,uuid,uuid,jsonb,jsonb) from public;
revoke execute on function public.anaira_booking_rule_check(uuid,uuid,uuid,date,date) from anon;
revoke execute on function public.anaira_booking_rule_check(uuid,uuid,uuid,date,date) from public;
revoke execute on function public.anaira_calculate_hotel_premium_quote(uuid,uuid,uuid,date,date,integer,integer,text,jsonb) from anon;
revoke execute on function public.anaira_calculate_hotel_premium_quote(uuid,uuid,uuid,date,date,integer,integer,text,jsonb) from public;
revoke execute on function public.anaira_create_multi_room_booking_transaction(uuid,text,text,text,date,date,jsonb,text,text,text,uuid) from anon;
revoke execute on function public.anaira_create_multi_room_booking_transaction(uuid,text,text,text,date,date,jsonb,text,text,text,uuid) from public;
revoke execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) from anon;
revoke execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) from public;
revoke execute on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from anon;
revoke execute on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from public;
revoke execute on function public.anaira_start_verified_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from anon;
revoke execute on function public.anaira_start_verified_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from public;
revoke execute on function public.anaira_start_verified_hotel_booking_transaction_v3(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid,uuid,text,text) from anon;
revoke execute on function public.anaira_start_verified_hotel_booking_transaction_v3(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid,uuid,text,text) from public;
revoke execute on function public.anaira_booking_ab_assign(uuid,text,text) from anon;
revoke execute on function public.anaira_booking_ab_assign(uuid,text,text) from public;
revoke execute on function public.anaira_start_public_camp_booking(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) from anon;
revoke execute on function public.anaira_start_public_camp_booking(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) from public;
revoke execute on function public.anaira_start_public_stay_booking(uuid,uuid,text,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) from anon;
revoke execute on function public.anaira_start_public_stay_booking(uuid,uuid,text,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) from public;

-- These public guest lookup/payment/cancel functions remain public by design and are separately constrained by booking code + guest phone.
