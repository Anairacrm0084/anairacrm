-- 046: remove public execution from legacy privileged SECURITY DEFINER helpers.
-- Public booking/delivery/reservation RPCs intentionally remain callable for public commerce flows.
revoke all on function public.anaira_bootstrap_super_admin(text,text,text) from public,anon,authenticated;
revoke all on function public.handle_new_auth_profile() from public,anon,authenticated;
revoke all on function public.rls_auto_enable() from public,anon,authenticated;
revoke execute on function public.anaira_enable_restaurant_store() from anon;
