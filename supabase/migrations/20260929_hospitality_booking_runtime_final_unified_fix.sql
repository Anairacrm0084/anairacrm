-- Hospitality booking runtime finalization.
-- Unique function names prevent PostgREST overload ambiguity.
-- Hotel retains publication validation; non-hotel hospitality types do not.
create or replace function public.anaira_public_hospitality_hms_room_availability(
  p_restaurant_id uuid,p_check_in date,p_check_out date,p_adults integer,p_children integer,p_hospitality_type text
)
returns table(room_type_id uuid,name text,description text,base_rate numeric,available_rooms integer,max_adults integer,max_children integer,image_urls jsonb,amenities jsonb)
language plpgsql security definer set search_path=public,pg_temp as $$
declare rt record; d date; physical int; blocked int; assigned int; unassigned int; day_available int; min_available int;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 if p_adults<1 or p_children<0 then raise exception 'At least 1 adult is required'; end if;
 if coalesce(lower(trim(p_hospitality_type)),'hotel')='hotel' and not exists(
   select 1 from public.anaira_store_memberships m join public.anaira_platform_stores s on s.id=m.store_id
   where m.restaurant_id=p_restaurant_id and m.enabled and s.store_type='hotel' and s.enabled and s.published
 ) then raise exception 'Hotel store is not published'; end if;
 for rt in select r.* from public.hms_room_types r
   where r.restaurant_id=p_restaurant_id and r.active
   and coalesce(r.hospitality_type,'hotel')=coalesce(nullif(lower(trim(p_hospitality_type)),''),'hotel')
   and coalesce(r.max_adults,0)>=p_adults and coalesce(r.max_children,0)>=p_children
   order by r.base_rate
 loop
   min_available:=null; d:=p_check_in;
   while d<p_check_out loop
     select count(*)::int into physical from public.hms_rooms rm where rm.restaurant_id=p_restaurant_id and rm.room_type_id=rt.id and rm.active=true;
     select count(*)::int into blocked from public.hms_rooms rm where rm.restaurant_id=p_restaurant_id and rm.room_type_id=rt.id and rm.active=true and lower(coalesce(rm.status,'')) in ('maintenance','out_of_order','blocked','inactive');
     select count(*)::int into assigned from public.hms_reservations rs where rs.restaurant_id=p_restaurant_id and rs.room_type_id=rt.id and rs.room_id is not null and rs.check_in<=d and rs.check_out>d and lower(coalesce(rs.status,'')) not in ('cancelled','canceled','no_show','no-show','checked_out');
     select count(*)::int into unassigned from public.hms_reservations rs where rs.restaurant_id=p_restaurant_id and rs.room_type_id=rt.id and rs.room_id is null and rs.check_in<=d and rs.check_out>d and lower(coalesce(rs.status,'')) not in ('cancelled','canceled','no_show','no-show','checked_out');
     day_available:=greatest(0,physical-blocked-assigned-unassigned);
     select case when exists(select 1 from public.hms_inventory i where i.restaurant_id=p_restaurant_id and i.room_type_id=rt.id and i.stay_date=d and i.closed) then 0 else day_available end into day_available;
     min_available:=case when min_available is null then day_available else least(min_available,day_available) end; d:=d+1;
   end loop;
   if coalesce(min_available,0)>0 then
     room_type_id:=rt.id; name:=rt.name; description:=coalesce(rt.short_description,rt.description,''); base_rate:=rt.base_rate; available_rooms:=min_available; max_adults:=rt.max_adults; max_children:=rt.max_children; image_urls:=rt.image_urls; amenities:=rt.amenities; return next;
   end if;
 end loop;
end $$;

create or replace function public.anaira_public_hospitality_room_availability_by_id(
 p_restaurant_id uuid,p_check_in date,p_check_out date,p_adults integer,p_children integer,p_hospitality_type text
)
returns table(room_type_id uuid,name text,code text,max_occupancy integer,base_rate numeric,available_rooms integer)
language plpgsql security definer set search_path=public,pg_temp as $$
declare x record;
begin
 for x in select * from public.anaira_public_hospitality_hms_room_availability(p_restaurant_id,p_check_in,p_check_out,p_adults,p_children,p_hospitality_type)
 loop
  room_type_id:=x.room_type_id; name:=x.name; code:=(select rt.code from public.hms_room_types rt where rt.id=x.room_type_id); max_occupancy:=coalesce(x.max_adults,0)+coalesce(x.max_children,0); base_rate:=x.base_rate; available_rooms:=x.available_rooms; return next;
 end loop;
end $$;

grant execute on function public.anaira_public_hospitality_hms_room_availability(uuid,date,date,integer,integer,text) to anon,authenticated;
grant execute on function public.anaira_public_hospitality_room_availability_by_id(uuid,date,date,integer,integer,text) to anon,authenticated;
