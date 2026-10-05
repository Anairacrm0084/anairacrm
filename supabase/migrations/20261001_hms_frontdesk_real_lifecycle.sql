-- HMS front-desk lifecycle completion for the canonical hms_* model.
-- Uses the same restaurant/property tenant guard as the existing Phase 86 functions.
create or replace function public.anaira_hms_reservation_transition(p_restaurant_id uuid,p_reservation_id uuid,p_action text,p_room_id uuid default null,p_notes text default null)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.hms_reservations%rowtype; old_room public.hms_rooms%rowtype; new_room public.hms_rooms%rowtype; s public.hms_stays%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not(p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 select * into r from public.hms_reservations where id=p_reservation_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'HMS reservation not found'; end if;
 if p_action='cancel' then
   if r.status in ('checked_out','cancelled','no_show') then raise exception 'Reservation cannot be cancelled from %',r.status; end if;
   update public.hms_reservations set status='cancelled',notes=coalesce(p_notes,notes),updated_at=now() where id=r.id;
   if r.room_id is not null then update public.hms_rooms set status='available',guest_name=null,updated_at=now() where id=r.room_id and status<>'occupied'; end if;
 elsif p_action='no_show' then
   if r.status<>'confirmed' then raise exception 'Only confirmed reservations can be marked no-show'; end if;
   update public.hms_reservations set status='no_show',notes=coalesce(p_notes,notes),updated_at=now() where id=r.id;
 elsif p_action='room_move' then
   if r.status<>'checked_in' then raise exception 'Only checked-in reservations can move rooms'; end if;
   if p_room_id is null then raise exception 'New room is required'; end if;
   select * into new_room from public.hms_rooms where id=p_room_id and restaurant_id=p_restaurant_id for update;
   if not found or new_room.active is not true then raise exception 'New room not found or inactive'; end if;
   if new_room.status<>'available' or new_room.housekeeping_status not in ('clean','inspected') then raise exception 'New room is not clean and available'; end if;
   if new_room.room_type_id is distinct from r.room_type_id then raise exception 'New room type does not match reservation'; end if;
   if r.room_id is not null then select * into old_room from public.hms_rooms where id=r.room_id for update; update public.hms_rooms set status='available',guest_name=null,updated_at=now() where id=r.room_id; end if;
   update public.hms_rooms set status='occupied',housekeeping_status='dirty',guest_name=(select full_name from public.hms_guests where id=r.guest_id),updated_at=now() where id=new_room.id;
   update public.hms_reservations set room_id=new_room.id,notes=coalesce(p_notes,notes),updated_at=now() where id=r.id;
   select * into s from public.hms_stays where reservation_id=r.id and status='in_house' order by check_in_at desc limit 1 for update;
   if s.id is not null then update public.hms_stays set room_id=new_room.id,actual_room_id=new_room.id,notes=coalesce(p_notes,notes),updated_at=now() where id=s.id; end if;
 elsif p_action='checkout' then
   select * into s from public.hms_stays where reservation_id=r.id and status='in_house' order by check_in_at desc limit 1 for update;
   if s.id is null then raise exception 'No active in-house stay found'; end if;
   if coalesce(r.balance_amount,0)>0 then raise exception 'Outstanding balance must be zero before check-out'; end if;
   update public.hms_stays set status='checked_out',check_out_at=now(),notes=coalesce(p_notes,notes),updated_at=now() where id=s.id;
   update public.hms_rooms set status='dirty',housekeeping_status='dirty',last_status_changed_at=now(),updated_at=now() where id=s.actual_room_id and restaurant_id=p_restaurant_id;
   update public.hms_reservations set status='checked_out',updated_at=now() where id=r.id;
   insert into public.hms_housekeeping_tasks(restaurant_id,room_id,task_type,priority,status,due_at,notes) values(p_restaurant_id,s.actual_room_id,'checkout_cleaning','high','pending',now(),coalesce(p_notes,'Checkout cleaning'));
 else raise exception 'Unsupported HMS reservation action: %',p_action; end if;
 return jsonb_build_object('ok',true,'reservation_id',r.id,'action',p_action,'status',(select status from public.hms_reservations where id=r.id),'room_id',(select room_id from public.hms_reservations where id=r.id));
end $$;
revoke all on function public.anaira_hms_reservation_transition(uuid,uuid,text,uuid,text) from public;
grant execute on function public.anaira_hms_reservation_transition(uuid,uuid,text,uuid,text) to authenticated;
