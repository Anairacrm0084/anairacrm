-- Anaira production runtime hardening. Safe to run repeatedly.
create table if not exists public.anaira_api_rate_limits (
  rate_key text primary key,
  window_started_at timestamptz not null,
  request_count integer not null default 0,
  updated_at timestamptz not null default now()
);

create or replace function public.anaira_rate_limit_check(p_key text,p_limit integer,p_window_seconds integer)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  now_ts timestamptz := clock_timestamp();
  row_data public.anaira_api_rate_limits%rowtype;
  elapsed numeric;
  next_count integer;
  remaining integer;
  retry_seconds integer;
begin
  if coalesce(trim(p_key),'')='' or p_limit<1 or p_window_seconds<1 then
    raise exception 'Invalid rate limit parameters';
  end if;
  insert into public.anaira_api_rate_limits(rate_key,window_started_at,request_count,updated_at)
  values(p_key,now_ts,1,now_ts)
  on conflict(rate_key) do update
    set request_count=case when extract(epoch from (now_ts-public.anaira_api_rate_limits.window_started_at)) >= p_window_seconds then 1 else public.anaira_api_rate_limits.request_count+1 end,
        window_started_at=case when extract(epoch from (now_ts-public.anaira_api_rate_limits.window_started_at)) >= p_window_seconds then now_ts else public.anaira_api_rate_limits.window_started_at end,
        updated_at=now_ts
  returning * into row_data;
  elapsed:=extract(epoch from (now_ts-row_data.window_started_at));
  next_count:=row_data.request_count;
  remaining:=greatest(0,p_limit-next_count);
  retry_seconds:=greatest(1,ceil(p_window_seconds-elapsed)::integer);
  return jsonb_build_object('allowed',next_count<=p_limit,'remaining',remaining,'retry_after_seconds',retry_seconds,'count',next_count);
end $$;

revoke all on function public.anaira_rate_limit_check(text,integer,integer) from public, anon, authenticated;
grant execute on function public.anaira_rate_limit_check(text,integer,integer) to service_role;

alter table public.anaira_distribution_connections add column if not exists webhook_signature_required boolean not null default true;
alter table public.anaira_distribution_connections add column if not exists webhook_timestamp_tolerance_seconds integer not null default 300;
alter table public.anaira_distribution_connections add column if not exists webhook_secret_ref text;

alter table public.anaira_api_rate_limits enable row level security;
revoke all on table public.anaira_api_rate_limits from anon, authenticated;
grant all on table public.anaira_api_rate_limits to service_role;

create index if not exists idx_anaira_api_rate_limits_updated_at on public.anaira_api_rate_limits(updated_at);
