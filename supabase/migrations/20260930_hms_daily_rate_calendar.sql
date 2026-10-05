-- ANAIRA HMS DAILY RATE CALENDAR
-- EP / CP / MAP / AP per-day manual rate overrides.
create table if not exists public.hms_daily_rate_calendar (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null,
  hospitality_type text not null default 'hotel',
  room_type_id uuid references public.hms_room_types(id) on delete cascade,
  rate_plan_id uuid not null references public.hms_rate_plans(id) on delete cascade,
  stay_date date not null,
  single_rate numeric(12,2) not null default 0,
  double_rate numeric(12,2) not null default 0,
  triple_rate numeric(12,2) not null default 0,
  quad_rate numeric(12,2) not null default 0,
  extra_adult numeric(12,2) not null default 0,
  extra_child numeric(12,2) not null default 0,
  closed boolean not null default false,
  source text not null default 'manual',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(rate_plan_id, stay_date)
);
create index if not exists hms_daily_rate_calendar_lookup_idx on public.hms_daily_rate_calendar(restaurant_id,rate_plan_id,stay_date);
alter table public.hms_daily_rate_calendar enable row level security;
drop policy if exists hms_daily_rate_calendar_access on public.hms_daily_rate_calendar;
create policy hms_daily_rate_calendar_access on public.hms_daily_rate_calendar for all to authenticated
using(public.anaira_can_access_tenant(restaurant_id)) with check(public.anaira_can_access_tenant(restaurant_id));

create or replace function public.anaira_seed_daily_rate_calendar(
 p_restaurant_id uuid,p_rate_plan_id uuid,p_from date,p_to date
) returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare rp public.hms_rate_plans%rowtype; d date; n integer:=0; begin
 if p_to<p_from then raise exception 'Invalid date range'; end if;
 if not (p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_restaurant_id;
 if not found then raise exception 'Rate plan not found'; end if;
 for d in select generate_series(p_from,p_to,'1 day'::interval)::date loop
  insert into public.hms_daily_rate_calendar(restaurant_id,hospitality_type,room_type_id,rate_plan_id,stay_date,single_rate,double_rate,triple_rate,quad_rate,extra_adult,extra_child)
  values(p_restaurant_id,coalesce(rp.hospitality_type,'hotel'),rp.room_type_id,p_rate_plan_id,d,coalesce(rp.rate,0),coalesce(rp.rate,0),coalesce(rp.rate,0),coalesce(rp.rate,0),coalesce(rp.extra_adult,0),coalesce(rp.extra_child,0))
  on conflict(rate_plan_id,stay_date) do nothing;
  n:=n+1;
 end loop; return n; end $$;
revoke all on function public.anaira_seed_daily_rate_calendar(uuid,uuid,date,date) from public;
grant execute on function public.anaira_seed_daily_rate_calendar(uuid,uuid,date,date) to authenticated;

create or replace function public.anaira_set_daily_rate(
 p_restaurant_id uuid,p_rate_plan_id uuid,p_stay_date date,p_single numeric,p_double numeric,p_triple numeric,p_quad numeric,p_extra_adult numeric default 0,p_extra_child numeric default 0,p_closed boolean default false
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare rp public.hms_rate_plans%rowtype; r public.hms_daily_rate_calendar%rowtype; begin
 if not (p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_restaurant_id; if not found then raise exception 'Rate plan not found'; end if;
 insert into public.hms_daily_rate_calendar(restaurant_id,hospitality_type,room_type_id,rate_plan_id,stay_date,single_rate,double_rate,triple_rate,quad_rate,extra_adult,extra_child,closed,source,updated_at)
 values(p_restaurant_id,coalesce(rp.hospitality_type,'hotel'),rp.room_type_id,p_rate_plan_id,p_stay_date,coalesce(p_single,0),coalesce(p_double,0),coalesce(p_triple,0),coalesce(p_quad,0),coalesce(p_extra_adult,0),coalesce(p_extra_child,0),coalesce(p_closed,false),'manual',now())
 on conflict(rate_plan_id,stay_date) do update set single_rate=excluded.single_rate,double_rate=excluded.double_rate,triple_rate=excluded.triple_rate,quad_rate=excluded.quad_rate,extra_adult=excluded.extra_adult,extra_child=excluded.extra_child,closed=excluded.closed,source='manual',updated_at=now()
 returning * into r;
 return to_jsonb(r); end $$;
revoke all on function public.anaira_set_daily_rate(uuid,uuid,date,numeric,numeric,numeric,numeric,numeric,numeric,boolean) from public;
grant execute on function public.anaira_set_daily_rate(uuid,uuid,date,numeric,numeric,numeric,numeric,numeric,numeric,boolean) to authenticated;
