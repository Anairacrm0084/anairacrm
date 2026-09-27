-- Anaira Phase 86: India-time hotel check-in/checkout + live physical inventory lifecycle
-- Canonical HMS lifecycle: confirmed -> checked_in -> checked_out; room reserved/occupied/dirty -> clean -> available.

create or replace function public.anaira_pms_check_in(p_restaurant_id uuid,p_reservation_id uuid,p_room_id uuid,p_notes text default null,p_allow_early_checkin boolean default false)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.hms_reservations%rowtype; rm public.hms_rooms%rowtype; s public.hms_stays%rowtype; hs public.hms_settings%rowtype; local_now timestamp; checkin_at timestamp;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not(p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 select * into r from public.hms_reservations where id=p_reservation_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'Reservation not found'; end if;
 if r.status <> 'confirmed' then raise exception 'Reservation must be confirmed before check-in'; end if;
 select * into hs from public.hms_settings where restaurant_id=p_restaurant_id limit 1;
 local_now := now() at time zone coalesce(nullif(hs.timezone,''),'Asia/Kolkata');
 checkin_at := r.check_in::timestamp + coalesce(hs.check_in_time,'12:00:00'::time);
 if local_now < checkin_at and not p_allow_early_checkin then raise exception 'Hotel check-in time is % on %. Use Early Check-in for a manual early arrival.',to_char(coalesce(hs.check_in_time,'12:00:00'::time),'HH12:MI AM'),to_char(r.check_in,'DD Mon YYYY'); end if;
 if local_now::date > r.check_out then raise exception 'This reservation has already passed its checkout date'; end if;
 select * into rm from public.hms_rooms where id=p_room_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'Room not found'; end if;
 if rm.active is not true then raise exception 'Room is inactive'; end if;
 if rm.room_type_id is distinct from r.room_type_id then raise exception 'Room type does not match reservation'; end if;
 if rm.status <> 'available' or rm.housekeeping_status not in ('clean','inspected') then raise exception 'Room is not available and clean for check-in'; end if;
 if exists(select 1 from public.hms_stays where reservation_id=r.id and status='in_house') then raise exception 'Active stay already exists'; end if;
 update public.hms_reservations set room_id=rm.id,status='checked_in',updated_at=now() where id=r.id;
 update public.hms_rooms set status='occupied',housekeeping_status='dirty',last_status_changed_at=now(),updated_at=now() where id=rm.id;
 insert into public.hms_stays(restaurant_id,reservation_id,room_id,actual_room_id,check_in_at,status,key_count,notes,early_check_in) values(p_restaurant_id,r.id,rm.id,rm.id,now(),'in_house',1,p_notes,p_allow_early_checkin) returning * into s;
 insert into public.hms_folios(restaurant_id,reservation_id,guest_id,status,subtotal,tax,total,balance,paid_amount,deposit_amount) select p_restaurant_id,r.id,r.guest_id,'open',0,0,coalesce(r.total_amount,0),greatest(coalesce(r.total_amount,0)-coalesce(r.paid_amount,0),0),coalesce(r.paid_amount,0),coalesce(r.deposit_amount,0) where not exists(select 1 from public.hms_folios f where f.restaurant_id=p_restaurant_id and f.reservation_id=r.id);
 return jsonb_build_object('ok',true,'reservation_id',r.id,'stay_id',s.id,'room_id',rm.id,'reservation_status','checked_in','room_status','occupied','housekeeping_status','dirty','early_check_in',p_allow_early_checkin,'timezone',coalesce(nullif(hs.timezone,''),'Asia/Kolkata'),'check_in_time',coalesce(hs.check_in_time,'12:00:00'::time));
end $$;
revoke all on function public.anaira_pms_check_in(uuid,uuid,uuid,text,boolean) from public;
grant execute on function public.anaira_pms_check_in(uuid,uuid,uuid,text,boolean) to authenticated;

create or replace function public.anaira_phase13_pms_transition(p_restaurant_id uuid,p_reservation_id uuid,p_action text,p_room_id uuid default null,p_notes text default null)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.hms_reservations%rowtype; s public.hms_stays%rowtype; f public.hms_folios%rowtype; hs public.hms_settings%rowtype; local_now timestamp; checkout_at timestamp;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not(p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 select * into r from public.hms_reservations where id=p_reservation_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'HMS reservation not found'; end if;
 if p_action='checkout' then
  if coalesce(r.balance_amount,0)>0 then raise exception 'Outstanding balance must be zero before check-out'; end if;
  select * into hs from public.hms_settings where restaurant_id=p_restaurant_id limit 1;
  local_now := now() at time zone coalesce(nullif(hs.timezone,''),'Asia/Kolkata');
  checkout_at := r.check_out::timestamp + coalesce(hs.check_out_time,'11:00:00'::time);
  if local_now < checkout_at then raise exception 'Hotel checkout time is % on %. Use Late Check-out for an early departure.',to_char(coalesce(hs.check_out_time,'11:00:00'::time),'HH12:MI AM'),to_char(r.check_out,'DD Mon YYYY'); end if;
  select * into s from public.hms_stays where reservation_id=r.id and status='in_house' order by check_in_at desc limit 1 for update;
  if s.id is null then raise exception 'No in-house stay found'; end if;
  update public.hms_stays set status='checked_out',check_out_at=now(),notes=coalesce(p_notes,notes),updated_at=now() where id=s.id;
  update public.hms_rooms set status='dirty',housekeeping_status='dirty',last_status_changed_at=now(),updated_at=now() where id=s.room_id and restaurant_id=p_restaurant_id;
  update public.hms_reservations set status='checked_out',updated_at=now() where id=r.id;
  select * into f from public.hms_folios where restaurant_id=p_restaurant_id and reservation_id=r.id order by created_at desc limit 1;
  if f.id is not null then update public.hms_folios set status='closed',balance=0,closed_at=now(),updated_at=now() where id=f.id; end if;
  insert into public.hms_housekeeping_tasks(restaurant_id,room_id,task_type,priority,status,due_at,notes) values(p_restaurant_id,s.room_id,'checkout_cleaning','high','pending',now(),coalesce(p_notes,'Checkout cleaning'));
  return jsonb_build_object('ok',true,'reservation_id',r.id,'room_id',s.room_id,'status','checked_out');
 else raise exception 'Unsupported PMS action: %',p_action; end if;
end $$;
revoke all on function public.anaira_phase13_pms_transition(uuid,uuid,text,uuid,text) from public;
grant execute on function public.anaira_phase13_pms_transition(uuid,uuid,text,uuid,text) to authenticated;

create or replace function public.anaira_inventory_dashboard(p_restaurant_id uuid,p_start date,p_end date) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare result jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not(p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then raise exception 'Tenant access denied'; end if;
 perform public.anaira_sync_hotel_inventory_range(p_restaurant_id,p_start,p_end);
 select jsonb_build_object('timezone','Asia/Kolkata','india_today',(now() at time zone 'Asia/Kolkata')::date,'room_types',coalesce((select jsonb_agg(jsonb_build_object('id',rt.id,'name',rt.name,'code',rt.code,'rooms',coalesce((select jsonb_agg(jsonb_build_object('id',rm.id,'room_number',rm.room_number,'floor',rm.floor,'building',rm.building,'status',rm.status,'housekeeping_status',rm.housekeeping_status,'active',rm.active,'effective_status',case when exists(select 1 from public.hms_reservations r where r.restaurant_id=p_restaurant_id and r.room_id=rm.id and r.check_in<=p_start and r.check_out>p_start and lower(r.status)='checked_in') then 'occupied' when exists(select 1 from public.hms_reservations r where r.restaurant_id=p_restaurant_id and r.room_id=rm.id and r.check_in<=p_start and r.check_out>p_start and lower(r.status)='confirmed') then 'reserved' when lower(coalesce(rm.status,'')) in ('maintenance','out_of_order') then rm.status when lower(coalesce(rm.housekeeping_status,'')) not in ('clean','inspected') then rm.housekeeping_status else 'available' end,'effective_housekeeping_status',case when exists(select 1 from public.hms_reservations r where r.restaurant_id=p_restaurant_id and r.room_id=rm.id and r.check_in<=p_start and r.check_out>p_start and lower(r.status)='checked_in') then 'dirty' else rm.housekeeping_status end) order by rm.room_number) from public.hms_rooms rm where rm.restaurant_id=rt.restaurant_id and rm.room_type_id=rt.id and coalesce(rm.active,true)),'[]'::jsonb)) order by rt.name) from public.hms_room_types rt where rt.restaurant_id=p_restaurant_id),'[]'::jsonb),'inventory',coalesce((select jsonb_agg(jsonb_build_object('stay_date',i.stay_date,'room_type_id',i.room_type_id,'total_rooms',i.total_rooms,'sold_rooms',i.sold_rooms,'blocked_rooms',i.blocked_rooms,'closed',i.closed,'available_rooms',greatest(0,i.total_rooms-i.sold_rooms-i.blocked_rooms)) order by i.stay_date,i.room_type_id) from public.hms_inventory i where i.restaurant_id=p_restaurant_id and i.stay_date>=p_start and i.stay_date<p_end),'[]'::jsonb),'reservations',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'reservation_code',r.reservation_code,'room_type_id',r.room_type_id,'room_id',r.room_id,'room_number',rm.room_number,'status',r.status,'check_in',r.check_in,'check_out',r.check_out,'guest_name',g.full_name,'guest_phone',g.phone) order by r.check_in,r.reservation_code) from public.hms_reservations r left join public.hms_guests g on g.id=r.guest_id left join public.hms_rooms rm on rm.id=r.room_id where r.restaurant_id=p_restaurant_id and r.check_in<p_end and r.check_out>p_start and lower(coalesce(r.status,'')) in ('confirmed','checked_in')),'[]'::jsonb)) into result;
 return result; end $$;
revoke all on function public.anaira_inventory_dashboard(uuid,date,date) from public;
grant execute on function public.anaira_inventory_dashboard(uuid,date,date) to authenticated;
