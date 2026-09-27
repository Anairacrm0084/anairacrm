-- Anaira Phase 83: automatic hotel inventory derived from physical rooms + reservations
create or replace function public.anaira_sync_hotel_inventory_range(
  p_restaurant_id uuid,p_from date,p_to date
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp as $$
declare d date; rt record; total int; blocked int; sold int; days int:=0;
begin
 if p_to<=p_from then raise exception 'Invalid inventory range'; end if;
 d:=p_from;
 while d<p_to loop
   for rt in select id from public.hms_room_types where restaurant_id=p_restaurant_id loop
     select count(*)::int into total
       from public.hms_rooms rm
       where rm.restaurant_id=p_restaurant_id and rm.room_type_id=rt.id
         and coalesce(rm.active,true);
     select count(*)::int into blocked
       from public.hms_rooms rm
       where rm.restaurant_id=p_restaurant_id and rm.room_type_id=rt.id
         and coalesce(rm.active,true)
         and lower(coalesce(rm.status,'')) in ('maintenance','out_of_order');
     select count(*)::int into sold
       from public.hms_reservations r
       where r.restaurant_id=p_restaurant_id and r.room_type_id=rt.id
         and r.check_in<=d and r.check_out>d
         and lower(coalesce(r.status,'')) in ('confirmed','checked_in');
     insert into public.hms_inventory(
       restaurant_id,room_type_id,stay_date,total_rooms,sold_rooms,blocked_rooms,closed
     ) values (
       p_restaurant_id,rt.id,d,greatest(total,0),greatest(sold,0),greatest(blocked,0),false
     )
     on conflict(restaurant_id,room_type_id,stay_date) do update set
       total_rooms=excluded.total_rooms,
       sold_rooms=excluded.sold_rooms,
       blocked_rooms=excluded.blocked_rooms,
       updated_at=now();
   end loop;
   days:=days+1; d:=d+1;
 end loop;
 return jsonb_build_object('ok',true,'days',days);
end $$;

revoke all on function public.anaira_sync_hotel_inventory_range(uuid,date,date) from public;
grant execute on function public.anaira_sync_hotel_inventory_range(uuid,date,date) to authenticated;

create or replace function public.anaira_inventory_dashboard(
  p_restaurant_id uuid,p_start date,p_end date
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp as $$
declare result jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not (
   p_restaurant_id=public.anaira_current_restaurant_id()
   or public.anaira_current_is_super_admin()
 ) then raise exception 'Tenant access denied'; end if;

 perform public.anaira_sync_hotel_inventory_range(p_restaurant_id,p_start,p_end);

 select jsonb_build_object(
   'room_types',coalesce((
     select jsonb_agg(jsonb_build_object(
       'id',rt.id,'name',rt.name,'code',rt.code,
       'rooms',coalesce((
         select jsonb_agg(jsonb_build_object(
           'id',rm.id,'room_number',rm.room_number,'floor',rm.floor,
           'building',rm.building,'status',rm.status,
           'housekeeping_status',rm.housekeeping_status,'active',rm.active
         ) order by rm.room_number)
         from public.hms_rooms rm
         where rm.restaurant_id=rt.restaurant_id
           and rm.room_type_id=rt.id and coalesce(rm.active,true)
       ),'[]'::jsonb)
     ) order by rt.name)
     from public.hms_room_types rt
     where rt.restaurant_id=p_restaurant_id
   ),'[]'::jsonb),
   'inventory',coalesce((
     select jsonb_agg(jsonb_build_object(
       'stay_date',i.stay_date,'room_type_id',i.room_type_id,
       'total_rooms',i.total_rooms,'sold_rooms',i.sold_rooms,
       'blocked_rooms',i.blocked_rooms,'closed',i.closed,
       'available_rooms',greatest(0,i.total_rooms-i.sold_rooms-i.blocked_rooms)
     ) order by i.stay_date,i.room_type_id)
     from public.hms_inventory i
     where i.restaurant_id=p_restaurant_id
       and i.stay_date>=p_start and i.stay_date<p_end
   ),'[]'::jsonb),
   'reservations',coalesce((
     select jsonb_agg(jsonb_build_object(
       'id',r.id,'reservation_code',r.reservation_code,
       'room_type_id',r.room_type_id,'room_id',r.room_id,
       'room_number',rm.room_number,
       'status',r.status,'check_in',r.check_in,'check_out',r.check_out,
       'guest_name',g.full_name,'guest_phone',g.phone
     ) order by r.check_in,r.reservation_code)
     from public.hms_reservations r
     left join public.hms_guests g on g.id=r.guest_id
     left join public.hms_rooms rm on rm.id=r.room_id
     where r.restaurant_id=p_restaurant_id
       and r.check_in<p_end and r.check_out>p_start
       and lower(coalesce(r.status,'')) in ('confirmed','checked_in')
   ),'[]'::jsonb)
 ) into result;

 return result;
end $$;

revoke all on function public.anaira_inventory_dashboard(uuid,date,date) from public;
grant execute on function public.anaira_inventory_dashboard(uuid,date,date) to authenticated;

create or replace function public.anaira_inventory_reservation_sync_trigger()
returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare lo date; hi date; rid uuid;
begin
 rid:=coalesce(new.restaurant_id,old.restaurant_id);
 lo:=least(
   coalesce(new.check_in,old.check_in),
   coalesce(old.check_in,new.check_in),
   current_date
 );
 hi:=greatest(
   coalesce(new.check_out,old.check_out),
   coalesce(old.check_out,new.check_out),
   current_date+180
 );
 perform public.anaira_sync_hotel_inventory_range(rid,lo,hi);
 return coalesce(new,old);
end $$;

drop trigger if exists trg_hms_reservations_inventory_sync on public.hms_reservations;
create trigger trg_hms_reservations_inventory_sync
after insert or update of room_type_id,room_id,status,check_in,check_out
on public.hms_reservations
for each row execute function public.anaira_inventory_reservation_sync_trigger();

create or replace function public.anaira_inventory_room_sync_trigger()
returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
begin
 perform public.anaira_sync_hotel_inventory_range(
   coalesce(new.restaurant_id,old.restaurant_id),current_date,current_date+180
 );
 return coalesce(new,old);
end $$;

drop trigger if exists trg_hms_rooms_inventory_sync on public.hms_rooms;
create trigger trg_hms_rooms_inventory_sync
after insert or update of room_type_id,status,active
on public.hms_rooms
for each row execute function public.anaira_inventory_room_sync_trigger();
