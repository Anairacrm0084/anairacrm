-- 043: user override precedence: an explicit user override wins over role/profile grants.
create or replace function public.anaira_user_has_permission(p_permission_key text) returns boolean
language sql stable security definer set search_path=public as $$
with me as (
  select p.id,p.role,p.restaurant_id,p.is_super_admin from public.profiles p where p.id=auth.uid()
), override_row as (
  select up.allowed from public.anaira_user_permissions up join me on me.id=up.user_id and me.restaurant_id=up.restaurant_id where up.permission_key=p_permission_key limit 1
)
select case
  when exists(select 1 from me where is_super_admin=true) then true
  when exists(select 1 from override_row) then (select allowed from override_row)
  else exists(
    select 1 from me
    left join public.anaira_user_profiles u on u.user_id=me.id and u.restaurant_id=me.restaurant_id
    left join public.anaira_profile_permissions pp on pp.profile_key=u.profile_key and pp.permission_key=p_permission_key
    left join public.anaira_role_permissions rp on rp.role_key=me.role and rp.permission_key=p_permission_key
    where pp.permission_key is not null or rp.permission_key is not null
  )
end;
$$;
revoke all on function public.anaira_user_has_permission(text) from public,anon;
grant execute on function public.anaira_user_has_permission(text) to authenticated;
