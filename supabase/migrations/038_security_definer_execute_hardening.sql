revoke execute on function public.anaira_can_access_tenant(uuid) from anon;
revoke execute on function public.anaira_current_restaurant_id() from anon;
revoke execute on function public.anaira_set_user_permission(uuid,uuid,text,boolean) from anon;
revoke execute on function public.anaira_user_has_permission(text) from anon;
revoke execute on function public.anaira_assign_business_user(uuid,uuid,text,text) from anon;
revoke execute on function public.anaira_create_property(text,text,text,text,text) from anon;
revoke execute on function public.anaira_current_is_super_admin() from anon;
