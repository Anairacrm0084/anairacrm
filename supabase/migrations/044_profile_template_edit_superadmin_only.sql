-- 044: global profile templates are platform definitions; only Super Admin may edit them.
create or replace function public.anaira_set_profile_permission(p_profile_key text,p_permission_key text,p_allowed boolean) returns void
language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_super_admin=true) then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
  if not exists(select 1 from public.anaira_permission_profiles where profile_key=p_profile_key) then raise exception 'PROFILE_NOT_FOUND'; end if;
  if not exists(select 1 from public.anaira_permissions where permission_key=p_permission_key) then raise exception 'PERMISSION_NOT_FOUND'; end if;
  if p_allowed then insert into public.anaira_profile_permissions(profile_key,permission_key) values(p_profile_key,p_permission_key) on conflict do nothing;
  else delete from public.anaira_profile_permissions where profile_key=p_profile_key and permission_key=p_permission_key; end if;
end; $$;
revoke all on function public.anaira_set_profile_permission(text,text,boolean) from public,anon;
grant execute on function public.anaira_set_profile_permission(text,text,boolean) to authenticated;
