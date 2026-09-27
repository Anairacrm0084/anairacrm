-- Tenant isolation for new plugin tables. A user can access only the restaurant in profiles.restaurant_id.
do $$ declare t text; begin
 foreach t in array array['booking_room_types','booking_rate_plans','booking_inventory','booking_reservations','booking_addons','restaurant_reservation_tables','restaurant_reservations','restaurant_waitlist','delivery_orders','delivery_order_items','delivery_riders','restaurant_storefronts','storefront_domains','storefront_sync_state','ota_channels','ota_room_mappings','ota_rate_mappings','ota_sync_events','anaira_platform_events','anaira_plugin_dependencies','pms_rooms','pms_reservations','pms_housekeeping_tasks'] loop
   execute format('alter table public.%I enable row level security',t);
 end loop;
end $$;

-- Restaurant-owned tables use a direct restaurant_id policy.
drop policy if exists tenant_access on public.booking_room_types;
create policy tenant_access on public.booking_room_types for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.booking_rate_plans;
create policy tenant_access on public.booking_rate_plans for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.booking_inventory;
create policy tenant_access on public.booking_inventory for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.booking_reservations;
create policy tenant_access on public.booking_reservations for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.booking_addons;
create policy tenant_access on public.booking_addons for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.pms_rooms;
create policy tenant_access on public.pms_rooms for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.pms_reservations;
create policy tenant_access on public.pms_reservations for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.pms_housekeeping_tasks;
create policy tenant_access on public.pms_housekeeping_tasks for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.restaurant_reservation_tables;
create policy tenant_access on public.restaurant_reservation_tables for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.restaurant_reservations;
create policy tenant_access on public.restaurant_reservations for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.restaurant_waitlist;
create policy tenant_access on public.restaurant_waitlist for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.delivery_orders;
create policy tenant_access on public.delivery_orders for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.delivery_riders;
create policy tenant_access on public.delivery_riders for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.restaurant_storefronts;
create policy tenant_access on public.restaurant_storefronts for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.storefront_sync_state;
create policy tenant_access on public.storefront_sync_state for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.ota_channels;
create policy tenant_access on public.ota_channels for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.ota_sync_events;
create policy tenant_access on public.ota_sync_events for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));
drop policy if exists tenant_access on public.anaira_platform_events;
create policy tenant_access on public.anaira_platform_events for all to authenticated using (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid())) with check (restaurant_id=(select restaurant_id from public.profiles where id=auth.uid()));

-- Child tables inherit isolation through their parent relationships at the application contract layer.
