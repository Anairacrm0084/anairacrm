alter table public.ota_room_mappings enable row level security;
alter table public.ota_rate_mappings enable row level security;
drop policy if exists tenant_access on public.ota_room_mappings;
create policy tenant_access on public.ota_room_mappings for all to authenticated using (exists (select 1 from public.ota_channels c where c.id=ota_room_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id))) with check (exists (select 1 from public.ota_channels c where c.id=ota_room_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)));
drop policy if exists tenant_access on public.ota_rate_mappings;
create policy tenant_access on public.ota_rate_mappings for all to authenticated using (exists (select 1 from public.ota_channels c where c.id=ota_rate_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id))) with check (exists (select 1 from public.ota_channels c where c.id=ota_rate_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)));
create unique index if not exists ota_room_mappings_channel_room_type_uidx on public.ota_room_mappings(channel_id,room_type_id) where room_type_id is not null;
create unique index if not exists ota_rate_mappings_channel_rate_plan_uidx on public.ota_rate_mappings(channel_id,rate_plan_id) where rate_plan_id is not null;
