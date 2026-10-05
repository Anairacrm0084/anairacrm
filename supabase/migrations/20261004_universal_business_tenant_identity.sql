-- Universal Business/Tenant Identity Layer
-- Keeps existing restaurant_id tenant scope backward compatible while adding
-- business verticals, locations, memberships and universal owner/staff identity.

alter table public.restaurants add column if not exists business_vertical text not null default 'restaurant';
alter table public.restaurants add column if not exists business_category text;
alter table public.restaurants add column if not exists subscription_plan text not null default 'starter';
alter table public.restaurants add column if not exists onboarding_status text not null default 'active';

create index if not exists restaurants_business_vertical_idx on public.restaurants(business_vertical);

create table if not exists public.anaira_business_locations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  code text,
  location_type text not null default 'branch',
  property_id uuid,
  address text,
  city text,
  state text,
  country text default 'India',
  postal_code text,
  phone text,
  email text,
  timezone text not null default 'Asia/Kolkata',
  currency text not null default 'INR',
  active boolean not null default true,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(business_id, code)
);

create index if not exists anaira_business_locations_business_idx on public.anaira_business_locations(business_id,active);

create table if not exists public.anaira_business_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid not null references public.restaurants(id) on delete cascade,
  location_id uuid references public.anaira_business_locations(id) on delete set null,
  role text not null default 'staff',
  profile_key text,
  status text not null default 'active',
  is_owner boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id,business_id)
);

create index if not exists anaira_business_memberships_user_idx on public.anaira_business_memberships(user_id,status);
create index if not exists anaira_business_memberships_business_idx on public.anaira_business_memberships(business_id,status);

alter table public.anaira_business_locations enable row level security;
alter table public.anaira_business_memberships enable row level security;

drop policy if exists anaira_business_locations_access on public.anaira_business_locations;
create policy anaira_business_locations_access on public.anaira_business_locations
for all to authenticated
using (
  public.anaira_current_is_super_admin()
  or business_id = public.anaira_current_restaurant_id()
  or exists(select 1 from public.anaira_business_memberships m where m.business_id=anaira_business_locations.business_id and m.user_id=auth.uid() and m.status='active')
)
with check (
  public.anaira_current_is_super_admin()
  or business_id = public.anaira_current_restaurant_id()
  or exists(select 1 from public.anaira_business_memberships m where m.business_id=anaira_business_locations.business_id and m.user_id=auth.uid() and m.status='active')
);

drop policy if exists anaira_business_memberships_access on public.anaira_business_memberships;
create policy anaira_business_memberships_access on public.anaira_business_memberships
for select to authenticated
using (public.anaira_current_is_super_admin() or user_id=auth.uid() or business_id=public.anaira_current_restaurant_id());

create or replace function public.anaira_create_universal_business(
  p_business_name text,
  p_business_vertical text,
  p_owner_name text default null,
  p_email text default null,
  p_phone text default null,
  p_address text default null,
  p_city text default null,
  p_state text default null,
  p_country text default 'India',
  p_location_name text default null
) returns uuid
language plpgsql security definer set search_path=public,pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_business uuid;
  v_slug text;
  v_location uuid;
  v_email text;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if nullif(trim(p_business_name),'') is null then raise exception 'BUSINESS_NAME_REQUIRED'; end if;
  if nullif(trim(p_business_vertical),'') is null then raise exception 'BUSINESS_VERTICAL_REQUIRED'; end if;

  v_email := coalesce(nullif(trim(p_email),''),(select email from auth.users where id=v_user));
  v_slug := regexp_replace(lower(trim(p_business_name)),'[^a-z0-9]+','-','g') || '-' || substr(replace(v_user::text,'-',''),1,8);

  insert into public.restaurants(name,slug,email,phone,address,city,state,country,status,business_vertical,business_category,onboarding_status)
  values(trim(p_business_name),v_slug,v_email,nullif(trim(p_phone),''),nullif(trim(p_address),''),nullif(trim(p_city),''),nullif(trim(p_state),''),coalesce(nullif(trim(p_country),''),'India'),'active',lower(trim(p_business_vertical)),lower(trim(p_business_vertical)),'active')
  returning id into v_business;

  insert into public.profiles(id,email,role,is_super_admin,status,full_name,restaurant_id)
  values(v_user,v_email,'admin',false,'active',coalesce(nullif(trim(p_owner_name),''),(select raw_user_meta_data->>'full_name' from auth.users where id=v_user)),v_business)
  on conflict(id) do update set role='admin',is_super_admin=false,status='active',full_name=coalesce(excluded.full_name,public.profiles.full_name),restaurant_id=v_business,updated_at=now();

  insert into public.anaira_business_memberships(user_id,business_id,role,profile_key,status,is_owner)
  values(v_user,v_business,'admin','business_admin','active',true)
  on conflict(user_id,business_id) do update set role='admin',profile_key='business_admin',status='active',is_owner=true,updated_at=now();

  insert into public.anaira_user_profiles(user_id,restaurant_id,profile_key)
  values(v_user,v_business,'business_admin')
  on conflict(user_id,restaurant_id) do update set profile_key='business_admin',updated_at=now();

  insert into public.anaira_business_locations(business_id,name,code,location_type,address,city,state,country,phone,email)
  values(v_business,coalesce(nullif(trim(p_location_name),''),trim(p_business_name)||' Main'), 'MAIN','branch',nullif(trim(p_address),''),nullif(trim(p_city),''),nullif(trim(p_state),''),coalesce(nullif(trim(p_country),''),'India'),nullif(trim(p_phone),''),v_email)
  returning id into v_location;

  return v_business;
end; $$;
revoke all on function public.anaira_create_universal_business(text,text,text,text,text,text,text,text,text,text) from public,anon;
grant execute on function public.anaira_create_universal_business(text,text,text,text,text,text,text,text,text,text) to authenticated;

create or replace function public.anaira_switch_business(p_business_id uuid) returns void
language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if not exists(select 1 from public.anaira_business_memberships where user_id=auth.uid() and business_id=p_business_id and status='active')
     and not public.anaira_current_is_super_admin() then raise exception 'BUSINESS_ACCESS_DENIED'; end if;
  update public.profiles set restaurant_id=p_business_id,updated_at=now() where id=auth.uid();
end; $$;
revoke all on function public.anaira_switch_business(uuid) from public,anon;
grant execute on function public.anaira_switch_business(uuid) to authenticated;

-- Backfill existing tenants as universal businesses without changing their current tenant IDs.
insert into public.anaira_business_memberships(user_id,business_id,role,profile_key,status,is_owner)
select p.id,p.restaurant_id,case when p.role='admin' then 'admin' else coalesce(p.role,'staff') end,
       case when p.role='admin' then 'business_admin' else null end,'active',p.role='admin'
from public.profiles p
where p.restaurant_id is not null and coalesce(p.is_super_admin,false)=false
on conflict(user_id,business_id) do nothing;

update public.restaurants set business_vertical=case
  when coalesce(hospitality_type,'') in ('hotel','camp','homestay','guest_house','cottage','resort','villa','hostel','farm_stay','lodge','motel','glamping') then coalesce(hospitality_type,'hotel')
  when lower(coalesce(business_type,'')) in ('restaurant','cafe','bakery') then lower(business_type)
  else coalesce(nullif(lower(business_vertical),''),'restaurant') end
where business_vertical is null or business_vertical='restaurant';
