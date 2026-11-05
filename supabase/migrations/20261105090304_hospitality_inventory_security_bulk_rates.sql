-- Hospitality production gate: safe public camp availability + bulk daily rates.
-- Non-destructive: preserves RPC return contract and does not invent inventory or prices.
create or replace function public.anaira_public_camp_availability(
 p_restaurant_id uuid,p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0
) returns table(unit_type_id uuid,available_units integer,max_guests integer,max_adults integer,max_children integer)
language sql security definer set search_path=public,pg_temp as $$
 select u.id,
   case when (select count(*) from public.camp_inventory i where i.restaurant_id=p_restaurant_id and i.unit_type_id=u.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed)=(p_check_out-p_check_in)
     then greatest(0,coalesce((select min(i.total_units-i.sold_units-i.held_units-i.blocked_units) from public.camp_inventory i where i.restaurant_id=p_restaurant_id and i.unit_type_id=u.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),0))::integer
     else 0 end,
   u.max_guests,u.max_adults,u.max_children
 from public.camp_unit_types u join public.camp_properties p on p.restaurant_id=u.restaurant_id
 where u.restaurant_id=p_restaurant_id and u.active and p.active and p.marketplace_visible
 and p_check_in>=current_date and p_check_out>p_check_in and p_check_out-p_check_in<=90
 and p_adults>=1 and p_children>=0 and p_adults<=u.max_adults and p_children<=u.max_children and p_adults+p_children<=u.max_guests;
$$;
revoke all on function public.anaira_public_camp_availability(uuid,date,date,integer,integer) from public;
grant execute on function public.anaira_public_camp_availability(uuid,date,date,integer,integer) to anon,authenticated;
drop policy if exists camp_inventory_public_select on public.camp_inventory;
revoke select on table public.camp_inventory from anon,public;

create or replace function public.anaira_bulk_set_daily_rate(
 p_restaurant_id uuid,p_rate_plan_id uuid,p_from date,p_to date,p_single numeric,p_double numeric,p_triple numeric,p_quad numeric,
 p_extra_adult numeric default 0,p_extra_child numeric default 0,p_closed boolean default false
) returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare rp public.hms_rate_plans%rowtype; affected integer:=0;
begin
 if p_from is null or p_to is null or p_to<p_from then raise exception 'Invalid bulk rate date range'; end if;
 if p_from<current_date or p_to-p_from>365 then raise exception 'Bulk rate update must be future-dated and limited to 366 dates'; end if;
 if not (p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_restaurant_id and active=true for update;
 if not found then raise exception 'Active rate plan not found for this property'; end if;
 if least(coalesce(p_single,0),coalesce(p_double,0),coalesce(p_triple,0),coalesce(p_quad,0),coalesce(p_extra_adult,0),coalesce(p_extra_child,0))<0 then raise exception 'Rates cannot be negative'; end if;
 insert into public.hms_daily_rate_calendar(restaurant_id,hospitality_type,room_type_id,rate_plan_id,stay_date,single_rate,double_rate,triple_rate,quad_rate,extra_adult,extra_child,closed,source,updated_at)
 select p_restaurant_id,coalesce(rp.hospitality_type,'hotel'),rp.room_type_id,p_rate_plan_id,d::date,coalesce(p_single,0),coalesce(p_double,0),coalesce(p_triple,0),coalesce(p_quad,0),coalesce(p_extra_adult,0),coalesce(p_extra_child,0),coalesce(p_closed,false),'bulk_manual',now()
 from generate_series(p_from::timestamp,p_to::timestamp,interval '1 day') as d
 on conflict(rate_plan_id,stay_date) do update set single_rate=excluded.single_rate,double_rate=excluded.double_rate,triple_rate=excluded.triple_rate,quad_rate=excluded.quad_rate,extra_adult=excluded.extra_adult,extra_child=excluded.extra_child,closed=excluded.closed,source='bulk_manual',updated_at=now();
 get diagnostics affected=row_count; return affected;
end; $$;
revoke all on function public.anaira_bulk_set_daily_rate(uuid,uuid,date,date,numeric,numeric,numeric,numeric,numeric,numeric,boolean) from public,anon;
grant execute on function public.anaira_bulk_set_daily_rate(uuid,uuid,date,date,numeric,numeric,numeric,numeric,numeric,numeric,boolean) to authenticated;
create index if not exists ana_plat_stores_parent_platform_store_idx on public.anaira_platform_stores(parent_platform_store_id);
notify pgrst,'reload schema';
