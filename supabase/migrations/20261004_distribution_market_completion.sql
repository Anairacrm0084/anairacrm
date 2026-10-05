-- Distribution market-completion data model: provider content mappings and reservation lifecycle.
create table if not exists public.ota_content_mappings (
 id uuid primary key default gen_random_uuid(),
 channel_id uuid not null references public.ota_channels(id) on delete cascade,
 entity_type text not null check(entity_type in ('property','room_type','rate_plan')),
 local_id uuid,
 external_code text not null,
 payload jsonb not null default '{}'::jsonb,
 content_hash text,
 status text not null default 'pending',
 last_synced_at timestamptz,
 last_error text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(channel_id,entity_type,local_id),
 unique(channel_id,entity_type,external_code)
);
create index if not exists ota_content_mappings_channel_status_idx on public.ota_content_mappings(channel_id,status);
alter table public.ota_content_mappings enable row level security;
drop policy if exists tenant_access on public.ota_content_mappings;
create policy tenant_access on public.ota_content_mappings for all to authenticated
using(exists(select 1 from public.ota_channels c where c.id=ota_content_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)))
with check(exists(select 1 from public.ota_channels c where c.id=ota_content_mappings.channel_id and public.anaira_tenant_access(c.restaurant_id)));

create table if not exists public.ota_reservation_lifecycle_events (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 connection_id uuid references public.anaira_distribution_connections(id) on delete set null,
 provider_code text not null,
 external_reservation_id text not null,
 lifecycle_action text not null check(lifecycle_action in ('create','modify','cancel','no_show','room_change','guest_change','date_change','rate_change','payment_change')),
 idempotency_key text not null unique,
 payload jsonb not null default '{}'::jsonb,
 status text not null default 'queued',
 error_message text,
 created_at timestamptz not null default now(),
 processed_at timestamptz
);
create index if not exists ota_reservation_lifecycle_tenant_idx on public.ota_reservation_lifecycle_events(restaurant_id,created_at desc);
alter table public.ota_reservation_lifecycle_events enable row level security;
drop policy if exists tenant_access on public.ota_reservation_lifecycle_events;
create policy tenant_access on public.ota_reservation_lifecycle_events for all to authenticated
using(public.anaira_tenant_access(restaurant_id)) with check(public.anaira_tenant_access(restaurant_id));
