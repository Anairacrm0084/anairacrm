-- 040: controlled tenant role assignment for Business Admins / Super Admins
create or replace function public.anaira_set_user_role(p_user_id uuid,p_restaurant_id uuid,p_role_key text) returns void
language plpgsql security definer set search_path=public as $$
begin
  if p_role_key not in ('admin','manager','staff') then raise exception 'INVALID_ROLE'; end if;
  if not exists(select 1 from public.profiles me where me.id=auth.uid() and (me.is_super_admin=true or (me.restaurant_id=p_restaurant_id and me.role='admin'))) then raise exception 'ADMIN_REQUIRED'; end if;
  if not exists(select 1 from public.profiles target where target.id=p_user_id and target.restaurant_id=p_restaurant_id and target.role<>'super_admin') then raise exception 'TARGET_USER_NOT_IN_TENANT'; end if;
  update public.profiles set role=p_role_key where id=p_user_id and restaurant_id=p_restaurant_id;
  delete from public.anaira_user_profiles where user_id=p_user_id and restaurant_id=p_restaurant_id;
end; $$;
revoke all on function public.anaira_set_user_role(uuid,uuid,text) from public,anon;
grant execute on function public.anaira_set_user_role(uuid,uuid,text) to authenticated;
