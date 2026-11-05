-- OTA distribution is available only to accommodation business records.
-- Existing restaurant/retail/clinic/etc. records remain untouched and are hidden/blocked.
create policy ota_property_scope_guard
on public.ota_channels as restrictive for all to public
using (exists (select 1 from public.restaurants r where r.id=ota_channels.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')))
with check (exists (select 1 from public.restaurants r where r.id=ota_channels.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')));

create policy distribution_connection_property_scope_guard
on public.anaira_distribution_connections as restrictive for all to public
using (exists (select 1 from public.restaurants r where r.id=anaira_distribution_connections.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')))
with check (exists (select 1 from public.restaurants r where r.id=anaira_distribution_connections.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')));

create policy ota_inbox_property_scope_guard
on public.anaira_ota_reservation_inbox as restrictive for all to public
using (exists (select 1 from public.restaurants r where r.id=anaira_ota_reservation_inbox.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')))
with check (exists (select 1 from public.restaurants r where r.id=anaira_ota_reservation_inbox.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')));

create policy ota_sync_property_scope_guard
on public.ota_sync_events as restrictive for all to public
using (exists (select 1 from public.restaurants r where r.id=ota_sync_events.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')))
with check (exists (select 1 from public.restaurants r where r.id=ota_sync_events.restaurant_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')));

create policy ota_room_mapping_property_scope_guard
on public.ota_room_mappings as restrictive for all to public
using (exists (select 1 from public.ota_channels c join public.restaurants r on r.id=c.restaurant_id where c.id=ota_room_mappings.channel_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')))
with check (exists (select 1 from public.ota_channels c join public.restaurants r on r.id=c.restaurant_id where c.id=ota_room_mappings.channel_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')));

create policy ota_rate_mapping_property_scope_guard
on public.ota_rate_mappings as restrictive for all to public
using (exists (select 1 from public.ota_channels c join public.restaurants r on r.id=c.restaurant_id where c.id=ota_rate_mappings.channel_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')))
with check (exists (select 1 from public.ota_channels c join public.restaurants r on r.id=c.restaurant_id where c.id=ota_rate_mappings.channel_id and r.business_type in ('hotel_resort','hotel_restaurant','camping')));
