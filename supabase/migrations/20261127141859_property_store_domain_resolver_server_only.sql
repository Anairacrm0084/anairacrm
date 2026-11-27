-- Domain resolution is performed by a server-only API using adminDb.
-- Do not expose an anonymous SECURITY DEFINER resolver over the Data API.
drop function if exists public.anaira_resolve_property_store_domain(text);
