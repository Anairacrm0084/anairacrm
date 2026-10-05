-- Anaira Distribution Runtime Completion
-- Durable sync/retry state, encrypted credentials reference, provider verification and webhook inbox.

alter table public.anaira_distribution_connections add column if not exists credentials_ciphertext text;
alter table public.anaira_distribution_connections add column if not exists connection_verified_at timestamptz;
alter table public.anaira_distribution_connections add column if not exists test_latency_ms integer;
alter table public.anaira_distribution_connections add column if not exists adapter_code text;
alter table public.anaira_distribution_connections add column if not exists provider_account_ref text;

alter table public.ota_sync_events add column if not exists attempt_count integer not null default 0;
alter table public.ota_sync_events add column if not exists max_attempts integer not null default 8;
alter table public.ota_sync_events add column if not exists next_attempt_at timestamptz not null default now();
alter table public.ota_sync_events add column if not exists locked_at timestamptz;
alter table public.ota_sync_events add column if not exists locked_by text;
alter table public.ota_sync_events add column if not exists completed_at timestamptz;
alter table public.ota_sync_events add column if not exists last_error text;
alter table public.ota_sync_events add column if not exists response_payload jsonb not null default '{}'::jsonb;
alter table public.ota_sync_events add column if not exists idempotency_key text;
alter table public.ota_sync_events add column if not exists connection_id uuid references public.anaira_distribution_connections(id) on delete set null;
create unique index if not exists ota_sync_events_idempotency_uidx on public.ota_sync_events(idempotency_key) where idempotency_key is not null;
create index if not exists ota_sync_events_worker_idx on public.ota_sync_events(status,next_attempt_at,created_at);

create table if not exists public.anaira_distribution_webhook_events (
 id uuid primary key default gen_random_uuid(),
 platform_id uuid references public.anaira_distribution_platforms(id) on delete set null,
 provider_code text not null,
 external_event_id text not null,
 idempotency_key text not null unique,
 event_type text not null,
 payload jsonb not null default '{}'::jsonb,
 status text not null default 'received',
 received_at timestamptz not null default now(),
 processed_at timestamptz,
 last_error text,
 attempts integer not null default 0
);
alter table public.anaira_distribution_webhook_events enable row level security;
drop policy if exists ana_distribution_webhook_access on public.anaira_distribution_webhook_events;
create policy ana_distribution_webhook_access on public.anaira_distribution_webhook_events for all to authenticated using (
 public.anaira_current_is_super_admin() or exists(select 1 from public.anaira_distribution_connections c where c.platform_id=anaira_distribution_webhook_events.platform_id and public.anaira_tenant_access(c.restaurant_id))
) with check (
 public.anaira_current_is_super_admin() or exists(select 1 from public.anaira_distribution_connections c where c.platform_id=anaira_distribution_webhook_events.platform_id and public.anaira_tenant_access(c.restaurant_id))
);
create index if not exists ana_dist_webhook_provider_status_idx on public.anaira_distribution_webhook_events(provider_code,status,received_at desc);

-- Connected must mean a successful connection verification, not a manually selected UI state.
create or replace function public.anaira_distribution_mark_verified(p_connection_id uuid,p_latency_ms integer default null)
returns public.anaira_distribution_connections
language plpgsql security definer set search_path=public
as $$
declare r public.anaira_distribution_connections;
begin
 update public.anaira_distribution_connections
 set status='connected', connection_verified_at=now(), test_latency_ms=p_latency_ms, last_error=null, updated_at=now()
 where id=p_connection_id and (public.anaira_current_is_super_admin() or public.anaira_tenant_access(restaurant_id))
 returning * into r;
 if r.id is null then raise exception 'Connection not found or access denied'; end if;
 return r;
end; $$;
revoke all on function public.anaira_distribution_mark_verified(uuid,integer) from public;
grant execute on function public.anaira_distribution_mark_verified(uuid,integer) to authenticated;


-- Prevent bypassing the Super Admin -> Property Connection -> Channel chain.
create or replace function public.anaira_distribution_channel_guard()
returns trigger language plpgsql security definer set search_path=public as $$
declare p public.anaira_distribution_platforms;
 c public.anaira_distribution_connections;
begin
 if new.platform_id is null then raise exception 'Distribution channel must reference a Super Admin platform.'; end if;
 select * into p from public.anaira_distribution_platforms where id=new.platform_id and active=true;
 if p.id is null then raise exception 'Distribution platform is disabled or missing.'; end if;
 select * into c from public.anaira_distribution_connections where restaurant_id=new.restaurant_id and platform_id=new.platform_id and status in ('configured','connected') limit 1;
 if c.id is null then raise exception 'Platform is not enabled/configured for this property by Super Admin.'; end if;
 new.provider=p.provider_name;
 if new.status is null then new.status='disconnected'; end if;
 return new;
end; $$;
drop trigger if exists trg_anaira_distribution_channel_guard on public.ota_channels;
create trigger trg_anaira_distribution_channel_guard before insert or update on public.ota_channels for each row execute function public.anaira_distribution_channel_guard();

create or replace function public.anaira_distribution_connection_guard()
returns trigger language plpgsql security definer set search_path=public as $$
declare p public.anaira_distribution_platforms;
begin
 select * into p from public.anaira_distribution_platforms where id=new.platform_id;
 if p.id is null then raise exception 'Distribution platform not found.'; end if;
 if p.integration_type <> 'internal' and new.status='connected' and new.connection_verified_at is null then
   raise exception 'External distribution connection must pass Test Connection before it can be marked connected.';
 end if;
 return new;
end; $$;
drop trigger if exists trg_anaira_distribution_connection_guard on public.anaira_distribution_connections;
create trigger trg_anaira_distribution_connection_guard before insert or update on public.anaira_distribution_connections for each row execute function public.anaira_distribution_connection_guard();
