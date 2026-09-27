-- 039: granular CRM permissions, job profiles and user profile assignments
-- Base roles remain: super_admin, admin, manager, staff.
create table if not exists public.anaira_permission_profiles (
  profile_key text primary key,
  name text not null,
  role_key text not null references public.anaira_roles(role_key) on delete cascade,
  description text,
  created_at timestamptz not null default now()
);
create table if not exists public.anaira_profile_permissions (
  profile_key text not null references public.anaira_permission_profiles(profile_key) on delete cascade,
  permission_key text not null references public.anaira_permissions(permission_key) on delete cascade,
  primary key(profile_key,permission_key)
);
create table if not exists public.anaira_user_profiles (
  user_id uuid not null references auth.users(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  profile_key text not null references public.anaira_permission_profiles(profile_key) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(user_id,restaurant_id)
);
alter table public.anaira_permission_profiles enable row level security;
alter table public.anaira_profile_permissions enable row level security;
alter table public.anaira_user_profiles enable row level security;

insert into public.anaira_permissions(permission_key,name,module,description)
select k, initcap(replace(replace(k,'.',' '),'_',' ')), split_part(k,'.',1), initcap(replace(replace(k,'.',' '),'_',' '))
from unnest(array[
'customer.view','customer.create','customer.edit','customer.delete','customer.export','customer.import',
'timeline.view','timeline.create','timeline.edit','task.view','task.create','task.assign','task.complete',
'lead.view','lead.create','lead.edit','lead.assign','lead.convert','lead.delete',
'corporate.view','corporate.create','corporate.edit','corporate.contract.manage',
'complaint.view','complaint.create','complaint.assign','complaint.edit','complaint.resolve','complaint.close',
'review.view','review.respond','review.manage','loyalty.view','loyalty.manage','loyalty.adjust','reward.issue',
'campaign.view','campaign.create','campaign.edit','campaign.launch','campaign.pause',
'segment.view','segment.create','segment.edit','segment.delete',
'report.view','report.export','report.financial','report.revenue',
'guest_request.view','guest_request.create','guest_request.assign','guest_request.complete',
'booking.view','booking.create','booking.edit','booking.cancel',
'pms.room.view','pms.room.create','pms.room.edit','pms.room.status',
'pms.reservation.view','pms.reservation.create','pms.reservation.edit','pms.reservation.cancel',
'housekeeping.task.view','housekeeping.task.assign','housekeeping.task.complete',
'reservation.view','reservation.create','reservation.edit','reservation.cancel',
'pos.order.view','pos.order.create','pos.order.edit','pos.order.void',
'pos.payment.collect','pos.payment.refund','pos.payment.close',
'delivery.order.view','delivery.order.assign','delivery.order.status',
'ota.sync.view','ota.sync.manage','store.view','store.manage',
'staff.view','staff.create','staff.edit','staff.disable','staff.reset_password','staff.assign_role','staff.assign_profile','staff.assign_permissions','staff.activity',
'approval.view','approval.manage',
'business.view','business.settings','crm.view','crm.manage','staff.manage','booking.manage','pms.manage','reservation.manage','pos.manage','delivery.manage','store.manage','ota.manage'
]::text[]) k
on conflict(permission_key) do update set name=excluded.name,module=excluded.module,description=excluded.description;

insert into public.anaira_permission_profiles(profile_key,name,role_key,description) values
('business_admin','Business Admin','admin','Full tenant administration and access control.'),
('hotel_manager','Hotel Manager','manager','Hotel and restaurant operations manager with team task and reporting access.'),
('front_desk','Front Desk','staff','Guest arrival, departure, booking and room-service workflow.'),
('reservation_agent','Reservation Agent','staff','Booking and restaurant reservation workflow.'),
('cashier','Cashier','staff','POS billing and payment collection workflow. Refund remains separately controlled.'),
('kitchen','Kitchen','staff','KOT/KDS and kitchen order workflow.'),
('housekeeping','Housekeeping','staff','Room status, cleaning queue and guest request workflow.'),
('restaurant_service','Restaurant Service','staff','Table reservation, POS order and guest service workflow.'),
('sales_executive','Sales Executive','staff','Leads, follow-ups, quotes, corporate and partner workflow.'),
('marketing_executive','Marketing Executive','staff','Segments, campaigns, reviews and marketing workflow.'),
('crm_executive','CRM Executive','staff','Customer 360, timeline, complaints, loyalty and CRM workflow.'),
('accountant','Accountant','staff','Financial reports and controlled payment/reconciliation access.'),
('read_only','Read Only','staff','View-only operational and CRM access.')
on conflict(profile_key) do update set name=excluded.name,role_key=excluded.role_key,description=excluded.description;

-- Business Admin gets the complete tenant permission catalog.
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'business_admin',permission_key from public.anaira_permissions on conflict do nothing;
-- Manager baseline is deliberately operational/CRM, without platform controls.
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'hotel_manager',permission_key from public.anaira_permissions
where permission_key not in ('business.settings','staff.create','staff.disable','staff.reset_password','staff.assign_role','staff.assign_profile','staff.assign_permissions','ota.sync.manage','store.manage','delivery.order.assign','pos.payment.refund','customer.delete')
on conflict do nothing;
-- Staff profiles are seeded by explicit module families; individual sensitive actions are separate permissions.
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'front_desk',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','customer.create','customer.edit','timeline.view','task.view','task.complete','booking.view','booking.create','booking.edit','booking.cancel','pms.room.view','pms.room.status','guest_request.view','guest_request.create','guest_request.complete','complaint.view','complaint.create','review.view') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'reservation_agent',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','customer.create','customer.edit','timeline.view','task.view','task.create','task.complete','booking.view','booking.create','booking.edit','booking.cancel','reservation.view','reservation.create','reservation.edit','reservation.cancel','lead.view','lead.create','lead.edit','lead.assign') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'cashier',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','pos.order.view','pos.order.create','pos.order.edit','pos.payment.collect','pos.payment.close','report.view') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'kitchen',permission_key from public.anaira_permissions where permission_key in ('business.view','pos.order.view','pos.order.edit') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'housekeeping',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','pms.room.view','pms.room.status','housekeeping.task.view','housekeeping.task.assign','housekeeping.task.complete','guest_request.view','guest_request.complete','complaint.view') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'restaurant_service',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','reservation.view','reservation.create','reservation.edit','reservation.cancel','pos.order.view','pos.order.create','pos.order.edit','guest_request.view','guest_request.create','guest_request.complete','complaint.view','complaint.create') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'sales_executive',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','customer.create','customer.edit','timeline.view','task.view','task.create','task.assign','task.complete','lead.view','lead.create','lead.edit','lead.assign','lead.convert','corporate.view','corporate.create','corporate.edit','corporate.contract.manage','report.view') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'marketing_executive',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','timeline.view','task.view','task.create','task.complete','segment.view','segment.create','segment.edit','campaign.view','campaign.create','campaign.edit','campaign.launch','campaign.pause','review.view','review.respond','report.view') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'crm_executive',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','customer.create','customer.edit','customer.delete','timeline.view','timeline.create','timeline.edit','task.view','task.create','task.assign','task.complete','lead.view','lead.create','lead.edit','lead.assign','complaint.view','complaint.create','complaint.assign','complaint.edit','complaint.resolve','review.view','review.respond','loyalty.view','loyalty.manage','loyalty.adjust','reward.issue','segment.view','segment.create','segment.edit','guest_request.view','guest_request.create','guest_request.assign','guest_request.complete') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'accountant',permission_key from public.anaira_permissions where permission_key in ('business.view','customer.view','report.view','report.export','report.financial','report.revenue','pos.payment.collect','pos.payment.refund','pos.payment.close','corporate.view') on conflict do nothing;
insert into public.anaira_profile_permissions(profile_key,permission_key)
select 'read_only',permission_key from public.anaira_permissions where permission_key in ('customer.view','timeline.view','task.view','lead.view','corporate.view','complaint.view','review.view','loyalty.view','campaign.view','segment.view','report.view','guest_request.view','booking.view','pms.room.view','pms.reservation.view','housekeeping.task.view','reservation.view','pos.order.view','delivery.order.view','ota.sync.view','store.view','staff.view','approval.view','business.view','crm.view') on conflict do nothing;

insert into public.anaira_role_permissions(role_key,permission_key)
select 'admin',permission_key from public.anaira_permissions on conflict do nothing;
insert into public.anaira_role_permissions(role_key,permission_key)
select 'manager',permission_key from public.anaira_profile_permissions where profile_key='hotel_manager' on conflict do nothing;

-- Read-only profile catalogs are safe to expose; assignments remain tenant scoped.
drop policy if exists "permission profiles read" on public.anaira_permission_profiles;
create policy "permission profiles read" on public.anaira_permission_profiles for select to authenticated using (true);
drop policy if exists "profile permissions read" on public.anaira_profile_permissions;
create policy "profile permissions read" on public.anaira_profile_permissions for select to authenticated using (true);
drop policy if exists "user profiles tenant access" on public.anaira_user_profiles;
create policy "user profiles tenant access" on public.anaira_user_profiles for all to authenticated
using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

create or replace function public.anaira_assign_user_profile(p_user_id uuid,p_restaurant_id uuid,p_profile_key text) returns void language plpgsql security definer set search_path=public as $$
declare v_role text; v_profile_role text;
begin
  select role into v_role from public.profiles where id=p_user_id and restaurant_id=p_restaurant_id;
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and (p.is_super_admin=true or (p.restaurant_id=p_restaurant_id and p.role='admin'))) then raise exception 'ADMIN_REQUIRED'; end if;
  if v_role is null then raise exception 'TARGET_USER_NOT_IN_TENANT'; end if;
  select role_key into v_profile_role from public.anaira_permission_profiles where profile_key=p_profile_key;
  if v_profile_role is null then raise exception 'PROFILE_NOT_FOUND'; end if;
  if v_profile_role<>v_role then raise exception 'PROFILE_ROLE_MISMATCH'; end if;
  insert into public.anaira_user_profiles(user_id,restaurant_id,profile_key,updated_at) values(p_user_id,p_restaurant_id,p_profile_key,now())
  on conflict(user_id,restaurant_id) do update set profile_key=excluded.profile_key,updated_at=now();
end; $$;
revoke all on function public.anaira_assign_user_profile(uuid,uuid,text) from public,anon;
grant execute on function public.anaira_assign_user_profile(uuid,uuid,text) to authenticated;

create or replace function public.anaira_set_profile_permission(p_profile_key text,p_permission_key text,p_allowed boolean) returns void language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and (p.is_super_admin=true or (p.restaurant_id is not null and p.role='admin'))) then raise exception 'ADMIN_REQUIRED'; end if;
  if not exists(select 1 from public.anaira_permission_profiles where profile_key=p_profile_key) then raise exception 'PROFILE_NOT_FOUND'; end if;
  if not exists(select 1 from public.anaira_permissions where permission_key=p_permission_key) then raise exception 'PERMISSION_NOT_FOUND'; end if;
  if p_allowed then insert into public.anaira_profile_permissions(profile_key,permission_key) values(p_profile_key,p_permission_key) on conflict do nothing;
  else delete from public.anaira_profile_permissions where profile_key=p_profile_key and permission_key=p_permission_key; end if;
end; $$;
revoke all on function public.anaira_set_profile_permission(text,text,boolean) from public,anon;
grant execute on function public.anaira_set_profile_permission(text,text,boolean) to authenticated;

create or replace function public.anaira_set_user_permission(p_user_id uuid,p_restaurant_id uuid,p_permission_key text,p_allowed boolean) returns void language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and (p.is_super_admin=true or (p.restaurant_id=p_restaurant_id and p.role='admin'))) then raise exception 'ADMIN_REQUIRED'; end if;
  if not exists(select 1 from public.profiles t where t.id=p_user_id and t.restaurant_id=p_restaurant_id) then raise exception 'TARGET_USER_NOT_IN_TENANT'; end if;
  if not exists(select 1 from public.anaira_permissions where permission_key=p_permission_key) then raise exception 'PERMISSION_NOT_FOUND'; end if;
  insert into public.anaira_user_permissions(user_id,restaurant_id,permission_key,allowed) values(p_user_id,p_restaurant_id,p_permission_key,p_allowed)
  on conflict(user_id,restaurant_id,permission_key) do update set allowed=excluded.allowed;
end; $$;
revoke all on function public.anaira_set_user_permission(uuid,uuid,text,boolean) from public,anon;
grant execute on function public.anaira_set_user_permission(uuid,uuid,text,boolean) to authenticated;

create or replace function public.anaira_user_has_permission(p_permission_key text) returns boolean language sql stable security definer set search_path=public as $$
select exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_super_admin=true)
or coalesce((select up.allowed from public.anaira_user_permissions up where up.user_id=auth.uid() and up.restaurant_id=(select p.restaurant_id from public.profiles p where p.id=auth.uid()) and up.permission_key=p_permission_key limit 1),false)
or exists(select 1 from public.profiles p join public.anaira_user_profiles u on u.user_id=p.id and u.restaurant_id=p.restaurant_id join public.anaira_profile_permissions pp on pp.profile_key=u.profile_key where p.id=auth.uid() and pp.permission_key=p_permission_key)
or exists(select 1 from public.profiles p join public.anaira_role_permissions rp on rp.role_key=p.role where p.id=auth.uid() and rp.permission_key=p_permission_key);
$$;
revoke all on function public.anaira_user_has_permission(text) from public,anon;
grant execute on function public.anaira_user_has_permission(text) to authenticated;

insert into public.anaira_user_profiles(user_id,restaurant_id,profile_key)
select p.id,p.restaurant_id,case when p.role='admin' then 'business_admin' else 'hotel_manager' end
from public.profiles p where p.restaurant_id is not null and p.role in ('admin','manager')
on conflict do nothing;
