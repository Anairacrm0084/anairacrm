-- V18 production hardening: RLS, FK indexes, trigger search_path and RPC exposure.

-- 1) Cover every public FK with an index where one is missing.
do $$
declare r record; idx_name text;
begin
  for r in
    select c.oid as table_oid, n.nspname as schema_name, c.relname as table_name,
           con.conname, con.conkey
    from pg_constraint con
    join pg_class c on c.oid=con.conrelid
    join pg_namespace n on n.oid=c.relnamespace
    where con.contype='f' and n.nspname='public' and c.relkind='r'
      and not exists (
        select 1 from pg_index i
        where i.indrelid=c.oid and i.indisvalid and i.indpred is null and i.indexprs is null
          and i.indnkeyatts >= array_length(con.conkey,1)
          and i.indkey[0:array_length(con.conkey,1)-1] = con.conkey
      )
  loop
    idx_name := 'idx_fk_' || substr(md5(r.schema_name||'.'||r.table_name||'.'||r.conname),1,16);
    execute format('create index if not exists %I on %I.%I (%s)',
      idx_name, r.schema_name, r.table_name,
      (select string_agg(format('%I',a.attname), ', ' order by u.ord)
       from unnest(r.conkey) with ordinality u(attnum,ord)
       join pg_attribute a on a.attrelid=r.table_oid and a.attnum=u.attnum));
  end loop;
end $$;

-- 2) Rate-limit state is admin/service data, never public data.
alter table public.anaira_api_rate_limits enable row level security;
drop policy if exists "anaira_api_rate_limits_service_access" on public.anaira_api_rate_limits;
create policy "anaira_api_rate_limits_service_access"
on public.anaira_api_rate_limits for all to authenticated
using (anaira_current_is_super_admin())
with check (anaira_current_is_super_admin());

-- 3) Trigger functions use a deterministic search_path.
alter function public.anaira_business_transaction_touch() set search_path = public;
alter function public.anaira_business_conversation_touch() set search_path = public;

-- 4) SECURITY DEFINER functions are not public by default.
--    Only explicitly public customer-facing booking/search RPCs retain anon access.
do $$
declare r record;
begin
  for r in
    select p.oid,n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) args
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f' and p.prosecdef
  loop
    execute format('revoke execute on function %I.%I(%s) from public',r.nspname,r.proname,r.args);
    execute format('revoke execute on function %I.%I(%s) from anon',r.nspname,r.proname,r.args);
    execute format('grant execute on function %I.%I(%s) to authenticated',r.nspname,r.proname,r.args);
  end loop;
end $$;

-- Explicit public RPC allow-list.
do $$
declare r record;
begin
  for r in
    select p.oid,n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) args
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f'
      and (
        p.proname like 'anaira_create_public_%'
        or p.proname like 'anaira_finalize_public_%'
        or p.proname in (
          'anaira_marketplace_availability','anaira_marketplace_business','anaira_marketplace_businesses',
          'anaira_marketplace_camp_search','anaira_marketplace_hms_hospitality_search',
          'anaira_marketplace_hotel_search','anaira_marketplace_stay_search',
          'anaira_public_booking_cancel','anaira_public_booking_invoice','anaira_public_booking_lookup',
          'anaira_public_booking_modify','anaira_public_booking_update_preferences',
          'anaira_public_camp_availability','anaira_public_hms_room_availability',
          'anaira_public_hospitality_hms_room_availability','anaira_public_hospitality_property_type',
          'anaira_public_hospitality_room_availability_by_id','anaira_public_restaurant_store_enabled',
          'anaira_public_room_availability_by_id','anaira_public_stay_availability'
        )
      )
  loop
    execute format('grant execute on function %I.%I(%s) to anon',r.nspname,r.proname,r.args);
    execute format('grant execute on function %I.%I(%s) to authenticated',r.nspname,r.proname,r.args);
  end loop;
end $$;
