-- Hotel Guest CRM / HMS checkout action compatibility.
-- UI historically sent `check_out`; the canonical PMS action is `checkout`.
-- Accept both spellings so older clients do not fail.
create or replace function public.anaira_phase13_pms_transition(
  p_restaurant_id uuid,
  p_reservation_id uuid,
  p_action text,
  p_room_id uuid default null,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  r public.hms_reservations%rowtype;
  s public.hms_stays%rowtype;
  f public.hms_folios%rowtype;
  hs public.hms_settings%rowtype;
  local_now timestamp;
  checkout_at timestamp;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not (p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
    then raise exception 'Tenant access denied'; end if;

  select * into r
  from public.hms_reservations
  where id=p_reservation_id and restaurant_id=p_restaurant_id
  for update;

  if not found then raise exception 'HMS reservation not found'; end if;

  if p_action='checkout' or p_action='check_out' then
    if coalesce(r.balance_amount,0)>0 then
      raise exception 'Outstanding balance must be zero before check-out';
    end if;

    select * into hs
    from public.hms_settings
    where restaurant_id=p_restaurant_id
    limit 1;

    local_now := now() at time zone coalesce(nullif(hs.timezone,''),'Asia/Kolkata');
    checkout_at := r.check_out::timestamp + coalesce(hs.check_out_time,'11:00:00'::time);

    if local_now < checkout_at then
      raise exception 'Hotel checkout time is % on %. Use Late Check-out for an early departure.',
        to_char(coalesce(hs.check_out_time,'11:00:00'::time),'HH12:MI AM'),
        to_char(r.check_out,'DD Mon YYYY');
    end if;

    select * into s
    from public.hms_stays
    where reservation_id=r.id and status='in_house'
    order by check_in_at desc
    limit 1
    for update;

    if s.id is null then raise exception 'No in-house stay found'; end if;

    update public.hms_stays
    set status='checked_out', check_out_at=now(), notes=coalesce(p_notes,notes), updated_at=now()
    where id=s.id;

    update public.hms_rooms
    set status='dirty', housekeeping_status='dirty', last_status_changed_at=now(), updated_at=now()
    where id=s.room_id and restaurant_id=p_restaurant_id;

    update public.hms_reservations
    set status='checked_out', updated_at=now()
    where id=r.id;

    select * into f
    from public.hms_folios
    where restaurant_id=p_restaurant_id and reservation_id=r.id
    order by created_at desc
    limit 1;

    if f.id is not null then
      update public.hms_folios
      set status='closed', balance=0, closed_at=now(), updated_at=now()
      where id=f.id;
    end if;

    insert into public.hms_housekeeping_tasks
      (restaurant_id,room_id,task_type,priority,status,due_at,notes)
    values
      (p_restaurant_id,s.room_id,'checkout_cleaning','high','pending',now(),coalesce(p_notes,'Checkout cleaning'));

    return jsonb_build_object('ok',true,'reservation_id',r.id,'room_id',s.room_id,'status','checked_out');
  else
    raise exception 'Unsupported PMS action: %',p_action;
  end if;
end $$;

revoke all on function public.anaira_phase13_pms_transition(uuid,uuid,text,uuid,text) from public;
grant execute on function public.anaira_phase13_pms_transition(uuid,uuid,text,uuid,text) to authenticated;
