-- P3: Restaurant CRM + Reservation Market Parity
-- Restaurant SaaS remains the operational POS/KOT/KDS/inventory source of truth.
-- CRM owns guest relationship, reservation lifecycle, preferences, waitlist and service context.

create table if not exists public.anaira_restaurant_reservation_events (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  reservation_id uuid not null references public.restaurant_reservations(id) on delete cascade,
  event_type text not null,
  from_status text,
  to_status text,
  actor_id uuid,
  idempotency_key text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(restaurant_id,idempotency_key)
);
create index if not exists anaira_rr_events_idx on public.anaira_restaurant_reservation_events(restaurant_id,reservation_id,created_at desc);

create table if not exists public.anaira_restaurant_table_combinations (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  capacity integer not null,
  active boolean not null default true,
  unique(restaurant_id,name)
);
create table if not exists public.anaira_restaurant_table_combination_members (
  combination_id uuid not null references public.anaira_restaurant_table_combinations(id) on delete cascade,
  table_id uuid not null references public.restaurant_reservation_tables(id) on delete cascade,
  primary key(combination_id,table_id)
);

create table if not exists public.anaira_restaurant_reservation_preferences (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  reservation_id uuid not null references public.restaurant_reservations(id) on delete cascade,
  customer_id uuid references public.crm_customers(id) on delete set null,
  preference_key text not null,
  preference_value text,
  source text not null default 'reservation',
  created_at timestamptz not null default now(),
  unique(reservation_id,preference_key)
);

create table if not exists public.anaira_restaurant_experiences (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  description text,
  active boolean not null default true,
  price numeric(14,2) not null default 0,
  currency text not null default 'INR',
  capacity integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.anaira_restaurant_reservation_addons (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  description text,
  active boolean not null default true,
  price numeric(14,2) not null default 0,
  currency text not null default 'INR',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(restaurant_id,name)
);
create table if not exists public.anaira_restaurant_reservation_addon_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  reservation_id uuid not null references public.restaurant_reservations(id) on delete cascade,
  addon_id uuid not null references public.anaira_restaurant_reservation_addons(id),
  quantity integer not null default 1 check(quantity>0),
  unit_price numeric(14,2) not null default 0,
  total numeric(14,2) generated always as (quantity*unit_price) stored,
  created_at timestamptz not null default now()
);

create table if not exists public.anaira_restaurant_reservation_deposits (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  reservation_id uuid not null references public.restaurant_reservations(id) on delete cascade,
  payment_intent_id uuid references public.anaira_payment_intents(id) on delete set null,
  amount numeric(14,2) not null check(amount>=0),
  currency text not null default 'INR',
  status text not null default 'required',
  refundable_amount numeric(14,2) not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.anaira_restaurant_reservation_events enable row level security;
alter table public.anaira_restaurant_table_combinations enable row level security;
alter table public.anaira_restaurant_table_combination_members enable row level security;
alter table public.anaira_restaurant_reservation_preferences enable row level security;
alter table public.anaira_restaurant_experiences enable row level security;
alter table public.anaira_restaurant_reservation_addons enable row level security;
alter table public.anaira_restaurant_reservation_addon_items enable row level security;
alter table public.anaira_restaurant_reservation_deposits enable row level security;

do $$ begin
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_reservation_events';
  execute 'create policy tenant_access on public.anaira_restaurant_reservation_events for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())';
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_table_combinations';
  execute 'create policy tenant_access on public.anaira_restaurant_table_combinations for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())';
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_table_combination_members';
  execute 'create policy tenant_access on public.anaira_restaurant_table_combination_members for all to authenticated using (exists(select 1 from public.anaira_restaurant_table_combinations c where c.id=combination_id and (public.anaira_current_is_super_admin() or c.restaurant_id=public.anaira_current_restaurant_id()))) with check (exists(select 1 from public.anaira_restaurant_table_combinations c where c.id=combination_id and (public.anaira_current_is_super_admin() or c.restaurant_id=public.anaira_current_restaurant_id())))';
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_reservation_preferences';
  execute 'create policy tenant_access on public.anaira_restaurant_reservation_preferences for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())';
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_experiences';
  execute 'create policy tenant_access on public.anaira_restaurant_experiences for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())';
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_reservation_addons';
  execute 'create policy tenant_access on public.anaira_restaurant_reservation_addons for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())';
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_reservation_addon_items';
  execute 'create policy tenant_access on public.anaira_restaurant_reservation_addon_items for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())';
  execute 'drop policy if exists tenant_access on public.anaira_restaurant_reservation_deposits';
  execute 'create policy tenant_access on public.anaira_restaurant_reservation_deposits for all to authenticated using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())';
end $$;

create or replace function public.anaira_restaurant_reservation_availability(
  p_restaurant_id uuid,p_date date,p_time time,p_party_size integer,p_duration_minutes integer default 90
) returns table(table_id uuid,table_number text,capacity integer,section text,available boolean)
language sql security definer set search_path=public,pg_temp as $$
  select t.id,t.table_number,t.capacity,t.section,not exists(
    select 1 from public.restaurant_reservations r
    where r.restaurant_id=p_restaurant_id and r.table_id=t.id
      and r.reservation_date=p_date and r.status in ('pending','requested','confirmed','seated')
      and (p_time < r.reservation_time + make_interval(mins=>coalesce(r.duration_minutes,90))
       and r.reservation_time < p_time + make_interval(mins=>greatest(p_duration_minutes,1)))
  )
  from public.restaurant_reservation_tables t
  where t.restaurant_id=p_restaurant_id and t.active and t.capacity>=greatest(p_party_size,1)
  order by t.capacity,t.table_number;
$$;
grant execute on function public.anaira_restaurant_reservation_availability(uuid,date,time,integer,integer) to anon,authenticated;

create or replace function public.anaira_create_restaurant_reservation_v2(
  p_restaurant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_date date,p_time time,
  p_party_size integer default 2,p_duration_minutes integer default 90,p_source text default 'direct',
  p_table_id uuid default null,p_idempotency_key text default null,p_special_request text default null
) returns public.restaurant_reservations
language plpgsql security definer set search_path=public,pg_temp as $$
declare rec public.restaurant_reservations; cid uuid; code text; chosen uuid; r public.restaurants;
begin
  if p_guest_name is null or btrim(p_guest_name)='' then raise exception 'Guest name is required'; end if;
  if p_party_size<1 or p_party_size>100 then raise exception 'Invalid party size'; end if;
  if p_date is null or p_time is null then raise exception 'Date and time are required'; end if;
  select * into r from public.restaurants where id=p_restaurant_id and status='active' for share;
  if r.id is null then raise exception 'Restaurant not found'; end if;
  if p_idempotency_key is not null then
    select e.payload->>'reservation_id' into code from public.anaira_restaurant_reservation_events e where e.restaurant_id=p_restaurant_id and e.idempotency_key=p_idempotency_key limit 1;
    if code is not null then select * into rec from public.restaurant_reservations where id=code::uuid; return rec; end if;
  end if;
  if p_table_id is not null then
    perform 1 from public.restaurant_reservation_tables t where t.id=p_table_id and t.restaurant_id=p_restaurant_id and t.active and t.capacity>=p_party_size for update;
    if not found then raise exception 'Selected table is unavailable'; end if;
    chosen:=p_table_id;
    if exists(select 1 from public.restaurant_reservations x where x.restaurant_id=p_restaurant_id and x.table_id=p_table_id and x.reservation_date=p_date and x.status in ('pending','requested','confirmed','seated') and (p_time < x.reservation_time + make_interval(mins=>coalesce(x.duration_minutes,90)) and x.reservation_time < p_time + make_interval(mins=>greatest(p_duration_minutes,1)))) then raise exception 'Selected table is already reserved for this time'; end if;
  else
    select t.id into chosen from public.restaurant_reservation_tables t where t.restaurant_id=p_restaurant_id and t.active and t.capacity>=p_party_size and not exists(select 1 from public.restaurant_reservations x where x.restaurant_id=p_restaurant_id and x.table_id=t.id and x.reservation_date=p_date and x.status in ('pending','requested','confirmed','seated') and (p_time < x.reservation_time + make_interval(mins=>coalesce(x.duration_minutes,90)) and x.reservation_time < p_time + make_interval(mins=>greatest(p_duration_minutes,1)))) order by t.capacity,t.table_number for update skip locked limit 1;
  end if;
  cid:=public.anaira_resolve_crm_customer(p_restaurant_id,p_guest_name,p_guest_phone,p_guest_email);
  code:='ANR-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.restaurant_reservations(restaurant_id,reservation_code,customer_id,guest_name,guest_phone,guest_email,reservation_date,reservation_time,party_size,duration_minutes,status,source,table_id,special_request)
  values(p_restaurant_id,code,cid,p_guest_name,p_guest_phone,p_guest_email,p_date,p_time,p_party_size,greatest(p_duration_minutes,1),'confirmed',coalesce(p_source,'direct'),chosen,p_special_request) returning * into rec;
  insert into public.anaira_restaurant_reservation_events(restaurant_id,reservation_id,event_type,to_status,actor_id,idempotency_key,payload) values(p_restaurant_id,rec.id,'created',rec.status,auth.uid(),coalesce(p_idempotency_key,rec.id::text),jsonb_build_object('reservation_id',rec.id,'reservation_code',rec.reservation_code,'customer_id',cid,'party_size',rec.party_size,'table_id',chosen));
  insert into public.crm_interactions(customer_id,channel,interaction_type,subject,notes) values(cid,'restaurant_reservation','reservation_created','Restaurant reservation created',jsonb_build_object('reservation_id',rec.id,'reservation_code',rec.reservation_code)::text);
  return rec;
end $$;
grant execute on function public.anaira_create_restaurant_reservation_v2(uuid,text,text,text,date,time,integer,integer,text,uuid,text,text) to anon,authenticated;

create or replace function public.anaira_update_restaurant_reservation_status(p_reservation_id uuid,p_status text,p_reason text default null,p_idempotency_key text default null)
returns public.restaurant_reservations language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.restaurant_reservations; old text; key text;
begin
  if p_status not in ('pending','requested','confirmed','seated','completed','cancelled','no_show') then raise exception 'Unsupported reservation status'; end if;
  select * into r from public.restaurant_reservations where id=p_reservation_id for update;
  if r.id is null then raise exception 'Reservation not found'; end if;
  key:=coalesce(p_idempotency_key,p_reservation_id::text||':'||p_status||':'||extract(epoch from clock_timestamp())::text);
  if exists(select 1 from public.anaira_restaurant_reservation_events where restaurant_id=r.restaurant_id and idempotency_key=key) then return r; end if;
  old:=r.status;
  update public.restaurant_reservations set status=p_status, special_request=case when p_reason is null then special_request else coalesce(special_request,'')||case when special_request is null or special_request='' then '' else ' | ' end||p_reason end, updated_at=now() where id=r.id returning * into r;
  insert into public.anaira_restaurant_reservation_events(restaurant_id,reservation_id,event_type,from_status,to_status,actor_id,idempotency_key,payload) values(r.restaurant_id,r.id,'status_changed',old,r.status,auth.uid(),key,jsonb_build_object('reason',p_reason));
  insert into public.anaira_platform_events(restaurant_id,event_name,source_plugin,aggregate_type,aggregate_id,payload) values(r.restaurant_id,'restaurant.reservation.status_changed','restaurant-reservation','reservation',r.id,jsonb_build_object('from_status',old,'to_status',r.status,'reservation_code',r.reservation_code));
  return r;
end $$;
grant execute on function public.anaira_update_restaurant_reservation_status(uuid,text,text,text) to authenticated;

drop view if exists public.anaira_restaurant_reservation_360;
create view public.anaira_restaurant_reservation_360 as
select r.*, c.full_name as crm_name,c.vip as crm_vip,c.total_restaurant_revenue,c.total_restaurant_visits,
       t.table_number,t.capacity as table_capacity,t.section
from public.restaurant_reservations r
left join public.crm_customers c on c.id=r.customer_id
left join public.restaurant_reservation_tables t on t.id=r.table_id;

comment on table public.anaira_restaurant_reservation_events is 'Auditable reservation lifecycle and idempotency history.';
comment on table public.anaira_restaurant_table_combinations is 'Optional table combinations; Restaurant SaaS remains operational table/POS authority.';
comment on table public.anaira_restaurant_reservation_deposits is 'Reservation deposit ledger linked to the existing Anaira payment-intent system.';
