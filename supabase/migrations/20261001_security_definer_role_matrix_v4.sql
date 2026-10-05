-- 2026-10-01 production security closure
-- Internal SECURITY DEFINER RPCs are never directly callable by anon.
-- Authenticated retains explicit EXECUTE. Only intentionally public search/availability/
-- public booking/finalization RPCs retain anon EXECUTE.
do $$
declare r record;
begin
  for r in
    select n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) args
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prosecdef
  loop
    execute format('revoke execute on function %I.%I(%s) from public',r.nspname,r.proname,r.args);
    execute format('grant execute on function %I.%I(%s) to authenticated',r.nspname,r.proname,r.args);
  end loop;

  for r in
    select n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) args
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prosecdef
      and (
        p.proname like 'anaira_public_%'
        or p.proname like 'anaira_marketplace_%'
        or p.proname like 'anaira_create_public_%'
        or p.proname like 'anaira_start_public_%'
        or p.proname like 'anaira_finalize_public_%'
      )
  loop
    execute format('grant execute on function %I.%I(%s) to anon',r.nspname,r.proname,r.args);
  end loop;
end $$;
