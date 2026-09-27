create or replace function public.anaira_current_is_super_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_super_admin=true); $$;
revoke all on function public.anaira_current_is_super_admin() from public;
grant execute on function public.anaira_current_is_super_admin() to authenticated;

create or replace function public.anaira_create_property(p_name text,p_slug text,p_email text default null,p_phone text default null,p_address text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare rid uuid;
begin
 if not public.anaira_current_is_super_admin() then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
 insert into public.restaurants(name,slug,email,phone,address,status) values(p_name,p_slug,p_email,p_phone,p_address,'active') returning id into rid;
 return rid;
end; $$;
revoke all on function public.anaira_create_property(text,text,text,text,text) from public;
grant execute on function public.anaira_create_property(text,text,text,text,text) to authenticated;

create or replace function public.anaira_assign_business_user(p_user_id uuid,p_restaurant_id uuid,p_role text default 'admin',p_full_name text default null)
returns void language plpgsql security definer set search_path=public as $$
begin
 if not public.anaira_current_is_super_admin() then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
 if not exists(select 1 from public.restaurants where id=p_restaurant_id) then raise exception 'PROPERTY_NOT_FOUND'; end if;
 insert into public.profiles(id,email,role,is_super_admin,status,full_name,restaurant_id)
 select u.id,u.email,p_role,false,'active',coalesce(p_full_name,u.raw_user_meta_data->>'full_name'),p_restaurant_id from auth.users u where u.id=p_user_id
 on conflict(id) do update set role=p_role,is_super_admin=false,status='active',full_name=coalesce(excluded.full_name,public.profiles.full_name),restaurant_id=p_restaurant_id,updated_at=now();
 if not found then raise exception 'AUTH_USER_NOT_FOUND'; end if;
end; $$;
revoke all on function public.anaira_assign_business_user(uuid,uuid,text,text) from public;
grant execute on function public.anaira_assign_business_user(uuid,uuid,text,text) to authenticated;
