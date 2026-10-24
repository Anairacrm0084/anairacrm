-- Anaira Daily Rate Calendar: tenant-safe bulk rate update.
-- Applies one occupancy/extra-guest/stop-sell configuration to every date in a bounded range.
create or replace function public.anaira_bulk_set_daily_rate(
 p_restaurant_id uuid,
 p_rate_plan_id uuid,
 p_from date,
 p_to date,
 p_single numeric,
 p_double numeric,
 p_triple numeric,
 p_quad numeric,
 p_extra_adult numeric default 0,
 p_extra_child numeric default 0,
 p_closed boolean default false
) returns integer
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
 rp public.hms_rate_plans%rowtype;
 affected integer := 0;
begin
 if p_from is null or p_to is null or p_to < p_from then
   raise exception 'Invalid bulk rate date range';
 end if;
 if p_to - p_from > 365 then
   raise exception 'Bulk rate update is limited to 366 dates';
 end if;
 if not (p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then
   raise exception 'Tenant access denied';
 end if;
 select * into rp from public.hms_rate_plans
  where id=p_rate_plan_id and restaurant_id=p_restaurant_id and active=true;
 if not found then raise exception 'Active rate plan not found for this property'; end if;
 if least(coalesce(p_single,0),coalesce(p_double,0),coalesce(p_triple,0),coalesce(p_quad,0),coalesce(p_extra_adult,0),coalesce(p_extra_child,0)) < 0 then
   raise exception 'Rates cannot be negative';
 end if;
 insert into public.hms_daily_rate_calendar(
   restaurant_id,hospitality_type,room_type_id,rate_plan_id,stay_date,
   single_rate,double_rate,triple_rate,quad_rate,extra_adult,extra_child,closed,source,updated_at
 )
 select p_restaurant_id,coalesce(rp.hospitality_type,'hotel'),rp.room_type_id,p_rate_plan_id,d::date,
   coalesce(p_single,0),coalesce(p_double,0),coalesce(p_triple,0),coalesce(p_quad,0),
   coalesce(p_extra_adult,0),coalesce(p_extra_child,0),coalesce(p_closed,false),'bulk_manual',now()
 from generate_series(p_from::timestamp,p_to::timestamp,interval '1 day') as d
 on conflict(rate_plan_id,stay_date) do update set
   single_rate=excluded.single_rate,
   double_rate=excluded.double_rate,
   triple_rate=excluded.triple_rate,
   quad_rate=excluded.quad_rate,
   extra_adult=excluded.extra_adult,
   extra_child=excluded.extra_child,
   closed=excluded.closed,
   source='bulk_manual',
   updated_at=now();
 get diagnostics affected = row_count;
 return affected;
end;
$$;
revoke all on function public.anaira_bulk_set_daily_rate(uuid,uuid,date,date,numeric,numeric,numeric,numeric,numeric,numeric,boolean) from public, anon;
grant execute on function public.anaira_bulk_set_daily_rate(uuid,uuid,date,date,numeric,numeric,numeric,numeric,numeric,numeric,boolean) to authenticated;
