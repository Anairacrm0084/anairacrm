-- Channel / OTA manager. Provider adapters are intentionally separate from PMS ownership.
create table if not exists public.ota_channels (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, provider text not null, status text not null default 'disconnected', credentials_ref text, last_sync_at timestamptz,
 settings jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), unique(restaurant_id,provider)
);
create table if not exists public.ota_room_mappings (
 id uuid primary key default gen_random_uuid(), channel_id uuid not null references public.ota_channels(id) on delete cascade,
 room_type_id uuid, external_code text not null, status text not null default 'mapped', metadata jsonb not null default '{}'::jsonb,
 unique(channel_id,external_code)
);
create table if not exists public.ota_rate_mappings (
 id uuid primary key default gen_random_uuid(), channel_id uuid not null references public.ota_channels(id) on delete cascade,
 rate_plan_id uuid, external_code text not null, status text not null default 'mapped', metadata jsonb not null default '{}'::jsonb,
 unique(channel_id,external_code)
);
create table if not exists public.ota_sync_events (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 channel_id uuid references public.ota_channels(id), event_type text not null, status text not null default 'queued', payload jsonb not null default '{}'::jsonb,
 error_message text, created_at timestamptz not null default now(), processed_at timestamptz
);
