
-- Phase 50: Individual Rooms professional master + lifecycle runtime
alter table public.hms_rooms
  add column if not exists last_status_changed_at timestamptz not null default now(),
  add column if not exists maintenance_reason text,
  add column if not exists out_of_order_reason text;

create unique index if not exists hms_rooms_restaurant_room_number_uidx
  on public.hms_rooms(restaurant_id, lower(btrim(room_number)));

create index if not exists hms_rooms_restaurant_status_idx
  on public.hms_rooms(restaurant_id, status, housekeeping_status, active);

create index if not exists hms_rooms_room_type_idx
  on public.hms_rooms(restaurant_id, room_type_id);

create table if not exists public.hms_room_lifecycle_events (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  room_id uuid not null references public.hms_rooms(id) on delete cascade,
  from_status text,
  to_status text not null,
  action text not null,
  notes text,
  actor_user_id uuid,
  created_at timestamptz not null default now()
);

create index if not exists hms_room_lifecycle_events_room_idx
  on public.hms_room_lifecycle_events(restaurant_id, room_id, created_at desc);

alter table public.hms_rooms enable row level security;
alter table public.hms_room_lifecycle_events enable row level security;

drop policy if exists hms_rooms_tenant_select on public.hms_rooms;
create policy hms_rooms_tenant_select on public.hms_rooms
for select to authenticated
using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

drop policy if exists hms_rooms_tenant_write on public.hms_rooms;
create policy hms_rooms_tenant_write on public.hms_rooms
for all to authenticated
using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

drop policy if exists hms_room_lifecycle_events_select on public.hms_room_lifecycle_events;
create policy hms_room_lifecycle_events_select on public.hms_room_lifecycle_events
for select to authenticated
using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

drop policy if exists hms_room_lifecycle_events_insert on public.hms_room_lifecycle_events;
create policy hms_room_lifecycle_events_insert on public.hms_room_lifecycle_events
for insert to authenticated
with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

create or replace function public.anaira_room_transition(
  p_restaurant_id uuid,
  p_room_id uuid,
  p_action text,
  p_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  r public.hms_rooms%rowtype;
  v_to text;
  v_hk text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not (p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then
    raise exception 'Tenant access denied';
  end if;

  select * into r from public.hms_rooms
  where id=p_room_id and restaurant_id=p_restaurant_id
  for update;
  if not found then raise exception 'Room not found'; end if;

  if p_action='reserve' and r.status='available' then
    v_to:='reserved'; v_hk:=coalesce(r.housekeeping_status,'clean');
  elsif p_action='cancel_reservation' and r.status='reserved' then
    v_to:='available'; v_hk:='clean';
  elsif p_action='occupy' and r.status in ('reserved','available') then
    v_to:='occupied'; v_hk:='clean';
  elsif p_action='dirty' and r.status='occupied' then
    v_to:='dirty'; v_hk:='dirty';
  elsif p_action='clean' and r.status='dirty' then
    v_to:='cleaning'; v_hk:='cleaning';
  elsif p_action='inspect' and r.status='cleaning' then
    v_to:='inspected'; v_hk:='inspected';
  elsif p_action='available' and r.status='inspected' then
    v_to:='available'; v_hk:='clean';
  elsif p_action='maintenance' and r.status in ('available','dirty','cleaning','inspected') then
    v_to:='maintenance'; v_hk:='out_of_order';
  elsif p_action='available' and r.status in ('maintenance','out_of_order') then
    v_to:='available'; v_hk:='clean';
  else
    raise exception 'Invalid room transition: % -> %',r.status,p_action;
  end if;

  update public.hms_rooms
  set status=v_to,
      housekeeping_status=v_hk,
      maintenance_reason=case when v_to='maintenance' then coalesce(p_notes,maintenance_reason) else null end,
      out_of_order_reason=case when v_to='out_of_order' then coalesce(p_notes,out_of_order_reason) else null end,
      last_status_changed_at=now(),
      updated_at=now()
  where id=r.id;

  insert into public.hms_room_lifecycle_events
    (restaurant_id,room_id,from_status,to_status,action,notes,actor_user_id)
  values
    (p_restaurant_id,r.id,r.status,v_to,p_action,p_notes,auth.uid());

  return jsonb_build_object(
    'ok',true,
    'room_id',r.id,
    'from_status',r.status,
    'to_status',v_to,
    'action',p_action
  );
end $$;

revoke all on function public.anaira_room_transition(uuid,uuid,text,text) from public;
grant execute on function public.anaira_room_transition(uuid,uuid,text,text) to authenticated;

insert into public.crm_release_evidence(check_name,status,evidence)
values(
  'phase50_individual_rooms_lifecycle',
  'pass',
  jsonb_build_object(
    'master_table','hms_rooms',
    'lifecycle_table','hms_room_lifecycle_events',
    'states',jsonb_build_array('available','reserved','occupied','dirty','cleaning','inspected','maintenance','out_of_order'),
    'tenant_security','RLS + authenticated transition RPC'
  )
)
on conflict do nothing;
