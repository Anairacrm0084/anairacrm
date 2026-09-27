-- 047: the store enable RPC is an authenticated/admin operation, not a public RPC.
revoke all on function public.anaira_enable_restaurant_store() from public;
grant execute on function public.anaira_enable_restaurant_store() to authenticated;
