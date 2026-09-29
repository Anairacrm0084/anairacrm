create or replace function public.anaira_public_hospitality_room_availability_by_id(
 p_restaurant_id uuid,p_check_in date,p_check_out date,p_adults integer,p_children integer,p_hospitality_type text
) returns table(room_type_id uuid,name text,code text,max_occupancy integer,base_rate numeric,available_rooms integer)
language plpgsql security definer set search_path=public,pg_temp as $$
declare x record;
begin
 for x in select * from public.anaira_public_hms_room_availability(p_restaurant_id,p_check_in,p_check_out,p_adults,p_children,p_hospitality_type) loop
  room_type_id:=x.room_type_id; name:=x.name; code:=(select rt.code from public.hms_room_types rt where rt.id=x.room_type_id);
  max_occupancy:=coalesce(x.max_adults,0)+coalesce(x.max_children,0); base_rate:=x.base_rate; available_rooms:=x.available_rooms; return next;
 end loop;
end $$;
grant execute on function public.anaira_public_hospitality_room_availability_by_id(uuid,date,date,integer,integer,text) to anon,authenticated;
