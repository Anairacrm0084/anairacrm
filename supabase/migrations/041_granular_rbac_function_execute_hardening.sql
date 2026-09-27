-- 041: keep RBAC SECURITY DEFINER RPCs unavailable to anonymous callers.
revoke execute on function public.anaira_assign_user_profile(uuid,uuid,text) from anon;
revoke execute on function public.anaira_set_profile_permission(text,text,boolean) from anon;
revoke execute on function public.anaira_set_user_permission(uuid,uuid,text,boolean) from anon;
revoke execute on function public.anaira_user_has_permission(text) from anon;
revoke execute on function public.anaira_set_user_role(uuid,uuid,text) from anon;
