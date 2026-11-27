-- Verification state and tokens must never be mutable through the browser Data API.
revoke insert,update,delete on public.anaira_property_store_domains from anon,authenticated;
grant select on public.anaira_property_store_domains to authenticated;
grant all on public.anaira_property_store_domains to service_role;
