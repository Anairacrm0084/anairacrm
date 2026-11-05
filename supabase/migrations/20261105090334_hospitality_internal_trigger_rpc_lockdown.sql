-- Trigger-only SECURITY DEFINER functions are not public RPC APIs.
revoke all on function public.anaira_ensure_hms_settings_for_hospitality() from public,anon,authenticated,service_role;
revoke all on function public.anaira_sync_business_capabilities() from public,anon,authenticated,service_role;
revoke all on function public.anaira_auto_enable_hms_from_hotel_store() from public,anon,authenticated,service_role;
revoke all on function public.anaira_auto_enable_hotel_management() from public,anon,authenticated,service_role;
-- Provisioning remains available to authenticated tenant users and service operations;
-- the function body independently enforces tenant/super-admin authorization.
revoke all on function public.anaira_ensure_property_store(uuid,text,text) from public,anon;
grant execute on function public.anaira_ensure_property_store(uuid,text,text) to authenticated,service_role;
