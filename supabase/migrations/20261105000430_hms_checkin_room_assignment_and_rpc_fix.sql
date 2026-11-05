-- Fix canonical HMS/PMS transition RPC: include check-in lifecycle and strict tenant/room validation.
-- The function argument names/order match the existing Booking Management client RPC contract.
create or replace function public.anaira_hms_reservation_transition(
  p_restaurant_id uuid,
  p_reservation_id uuid,
  p_action text,
  p_room_id uuid default null,
  p_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  v_user uuid := auth.uid();
  r public.hms_reservations%rowtype;
  rm public.hms_rooms%rowtype;
  s public.hms_stays%rowtype;
  f public.hms_folios%rowtype;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_restaurant_id is null or not (
    p_restaurant_id=public.anaira_current_restaurant_id()
    or public.anaira_current_is_super_admin()
  ) then raise exception 'Tenant access denied'; end if;

  select * into r from public.hms_reservations
   where id=p_reservation_id and restaurant_id=p_restaurant_id
   for update;
  if not found then raise exception 'HMS reservation not found'; end if;

  if p_action='check_in' then
    if r.status not in ('confirmed') then
      raise exception 'Only confirmed reservations can be checked in (current status: %)',r.status;
    end if;
    if p_room_id is null then raise exception 'Select an available room or tent before check-in'; end if;

    select * into rm from public.hms_rooms
     where id=p_room_id and restaurant_id=p_restaurant_id
     for update;
    if not found or rm.active is not true then raise exception 'Selected room/tent does not belong to this property or is inactive'; end if;
    if rm.hospitality_type is distinct from r.hospitality_type then
      raise exception 'Selected room/tent type does not match this reservation';
    end if;
    if rm.status<>'available' or rm.housekeeping_status not in ('clean','inspected') then
      raise exception 'Selected room/tent is not clean and available';
    end if;
    if r.room_type_id is not null and rm.room_type_id is distinct from r.room_type_id then
      raise exception 'Selected room type does not match the reservation';
    end if;

    select * into s from public.hms_stays
     where reservation_id=r.id and status='in_house'
     order by check_in_at desc limit 1 for update;
    if s.id is not null then
      raise exception 'This reservation already has an active check-in';
    end if;

    insert into public.hms_stays(
      restaurant_id,reservation_id,room_id,actual_room_id,check_in_at,status,key_count,notes
    ) values (
      p_restaurant_id,r.id,rm.id,rm.id,now(),'in_house',1,p_notes
    ) returning * into s;

    update public.hms_reservations
       set status='checked_in',room_id=rm.id,updated_at=now()
     where id=r.id and restaurant_id=p_restaurant_id;

    update public.hms_rooms
       set status='occupied',housekeeping_status='dirty',
           last_status_changed_at=now(),updated_at=now()
     where id=rm.id and restaurant_id=p_restaurant_id;

    select * into f from public.hms_folios
     where restaurant_id=p_restaurant_id and reservation_id=r.id
     order by created_at desc limit 1 for update;
    if f.id is null then
      insert into public.hms_folios(
        restaurant_id,reservation_id,guest_id,status,subtotal,tax,total,balance,paid_amount,deposit_amount
      ) values (
        p_restaurant_id,r.id,r.guest_id,'open',
        coalesce(r.total_amount,0),0,coalesce(r.total_amount,0),
        greatest(coalesce(r.balance_amount,r.total_amount,0),0),
        coalesce(r.paid_amount,0),coalesce(r.deposit_amount,0)
      ) returning * into f;
    end if;

  elsif p_action='room_move' then
    if r.status not in ('checked_in','in_house') then raise exception 'Only checked-in reservations can move rooms'; end if;
    if p_room_id is null then raise exception 'Target room/tent is required'; end if;
    select * into rm from public.hms_rooms
     where id=p_room_id and restaurant_id=p_restaurant_id
     for update;
    if not found or rm.active is not true then raise exception 'Target room/tent not found or inactive'; end if;
    if rm.hospitality_type is distinct from r.hospitality_type then raise exception 'Target room/tent type does not match reservation'; end if;
    if rm.status<>'available' or rm.housekeeping_status not in ('clean','inspected') then raise exception 'Target room/tent is not clean and available'; end if;
    if r.room_type_id is not null and rm.room_type_id is distinct from r.room_type_id then raise exception 'Target room type does not match reservation'; end if;
    select * into s from public.hms_stays
     where reservation_id=r.id and status='in_house'
     order by check_in_at desc limit 1 for update;
    if s.id is null then raise exception 'No active in-house stay found'; end if;
    update public.hms_rooms set status='available',updated_at=now()
     where id=s.actual_room_id and restaurant_id=p_restaurant_id;
    update public.hms_stays set room_id=rm.id,actual_room_id=rm.id,notes=coalesce(p_notes,notes),updated_at=now()
     where id=s.id;
    update public.hms_reservations set room_id=rm.id,updated_at=now()
     where id=r.id and restaurant_id=p_restaurant_id;
    update public.hms_rooms set status='occupied',housekeeping_status='dirty',
      guest_name=coalesce((select full_name from public.hms_guests where id=r.guest_id),guest_name),
      last_status_changed_at=now(),updated_at=now()
     where id=rm.id and restaurant_id=p_restaurant_id;

  elsif p_action='checkout' then
    select * into s from public.hms_stays
     where reservation_id=r.id and status='in_house'
     order by check_in_at desc limit 1 for update;
    if s.id is null then raise exception 'No active in-house stay found'; end if;
    if coalesce(r.balance_amount,0)>0 then raise exception 'Outstanding balance must be zero before check-out'; end if;
    update public.hms_stays set status='checked_out',check_out_at=now(),notes=coalesce(p_notes,notes),updated_at=now()
     where id=s.id;
    update public.hms_rooms set status='dirty',housekeeping_status='dirty',
      last_status_changed_at=now(),updated_at=now()
     where id=s.actual_room_id and restaurant_id=p_restaurant_id;
    update public.hms_reservations set status='checked_out',updated_at=now()
     where id=r.id and restaurant_id=p_restaurant_id;
    insert into public.hms_housekeeping_tasks(restaurant_id,room_id,task_type,priority,status,due_at,notes)
    values(p_restaurant_id,s.actual_room_id,'checkout_cleaning','high','pending',now(),coalesce(p_notes,'Checkout cleaning'));

  elsif p_action='no_show' then
    if r.status<>'confirmed' then raise exception 'Only confirmed reservations can be marked no-show'; end if;
    update public.hms_reservations set status='no_show',updated_at=now(),notes=coalesce(p_notes,notes)
     where id=r.id and restaurant_id=p_restaurant_id;

  elsif p_action='cancel' then
    if r.status in ('checked_out','cancelled','no_show') then raise exception 'Reservation cannot be cancelled from %',r.status; end if;
    if exists(select 1 from public.hms_stays where reservation_id=r.id and status='in_house') then
      raise exception 'Check out the active stay before cancelling this reservation';
    end if;
    update public.hms_reservations set status='cancelled',updated_at=now(),notes=coalesce(p_notes,notes)
     where id=r.id and restaurant_id=p_restaurant_id;
    if r.room_id is not null then
      update public.hms_rooms set status='available',guest_name=null,updated_at=now()
       where id=r.room_id and restaurant_id=p_restaurant_id and status<>'occupied';
    end if;
  else
    raise exception 'Unsupported HMS reservation action: %',p_action;
  end if;

  return jsonb_build_object(
    'ok',true,'reservation_id',r.id,'action',p_action,
    'status',(select status from public.hms_reservations where id=r.id and restaurant_id=p_restaurant_id),
    'room_id',(select room_id from public.hms_reservations where id=r.id and restaurant_id=p_restaurant_id),
    'stay_id',case when s.id is not null then s.id else null end
  );
end;
$$;

revoke all on function public.anaira_hms_reservation_transition(uuid,uuid,text,uuid,text) from public,anon;
grant execute on function public.anaira_hms_reservation_transition(uuid,uuid,text,uuid,text) to authenticated;
