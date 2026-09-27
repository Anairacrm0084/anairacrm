-- Loose-coupling event bus for optional plugins.
create table if not exists public.anaira_platform_events (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid references public.restaurants(id) on delete cascade,
 event_name text not null, source_plugin text not null, aggregate_type text, aggregate_id uuid,
 payload jsonb not null default '{}'::jsonb, status text not null default 'queued', created_at timestamptz not null default now(), processed_at timestamptz,
 error_message text
);
create index if not exists anaira_platform_events_queue_idx on public.anaira_platform_events(restaurant_id,status,created_at);
create table if not exists public.anaira_plugin_dependencies (
 plugin_key text not null references public.anaira_plugin_catalog(plugin_key) on delete cascade,
 dependency_key text not null references public.anaira_plugin_catalog(plugin_key) on delete cascade,
 dependency_type text not null default 'optional', created_at timestamptz not null default now(),
 primary key(plugin_key,dependency_key)
);
insert into public.anaira_plugin_dependencies(plugin_key,dependency_key,dependency_type) values
('hotel-booking','hotel-pms','optional'),('hotel-booking','crm','optional'),('hotel-pms','crm','optional'),
('restaurant-reservation','anaira-pos','optional'),('restaurant-reservation','crm','optional'),
('food-delivery','anaira-pos','optional'),('food-delivery','restaurant-store','optional'),('food-delivery','crm','optional'),
('restaurant-store','anaira-pos','optional'),('channel-manager','hotel-pms','optional'),('channel-manager','hotel-booking','optional')
on conflict do nothing;
