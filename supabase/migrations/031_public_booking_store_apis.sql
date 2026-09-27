-- Public, narrowly-scoped RPCs for guest-facing booking/store flows.
create or replace function public.an​​aira_find_restaurant_by_slug(p_slug text)
returns table(id uuid,name text,slug text,logo text,cover_image text,cuisine text,address text)
language sql stable security definer set search_path=public as $$
  select r.id,r.name,r.slug,r.logo,r.cover_image,r.cuisine,r.address from public.restaurants r where r.slug=p_slug and r.status='active' limit 1;
$$;

create or replace function public.anaira_public_room_availability(p_slug text,p_check_in date,p_check_out date,p_adults integer default 2,p_children integer default 0)
returns table(room_type_id uuid,name text,code text,max_occupancy integer,base_rate numeric,available_rooms integer)
language sql stable security definer set search_path=public as $$
  select rt.id,rt.name,rt.code,rt.max_occupancy,rt.base_rate,
    greatest(0,coalesce(sum(i.total_rooms-i.booked_rooms-i.held_rooms),0))::integer available_rooms
  from public.booking_room_types rt
  join public.restaurants r on r.id=rt.restaurant_id and r.slug=p_slug and r.status='active'
  left join public.booking_inventory i on i.room_type_id=rt.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and i.closed=false
  where rt.active=true and rt.max_occupancy >= greatest(1,p_adults+p_children)
  group by rt.id,rt.name,rt.code,rt.max_occupancy,rt.base_rate;
$$;

create or replace function public.anaira_create_public_booking(p_slug text,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_adults integer,p_children integer,p_source text default 'direct')
returns public.booking_reservations
language plpgsql security definer set search_path=public as $$
declare r public.restaurants; rt public.booking_room_types; code text;
begin
 select * into r from public.restaurants where slug=p_slug and status='active' limit 1;
 if r.id is null then raise exception 'Property not found'; end if;
 select * into rt from public.booking_room_types where id=p_room_type_id and restaurant_id=r.id and active=true;
 if rt.id is null then raise exception 'Room type not found'; end if;
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 code := 'ANB-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
 return query insert into public.booking_reservations(restaurant_id,booking_code,room_type_id,check_in,check_out,adults,children,guest_name,guest_phone,guest_email,status,payment_status,total_amount,source)
 values(r.id,code,rt.id,p_check_in,p_check_out,p_adults,p_children,p_guest_name,p_guest_phone,p_guest_email,'pending','unpaid',rt.base_rate*greatest(1,p_check_out-p_check_in),p_source) returning *;
end;
$$;

grant execute on function public.anaira_find_restaurant_by_slug(text) to anon,authenticated;
grant execute on function public.anaira_public_room_availability(text,date,date,integer,integer) to anon,authenticated;
grant execute on function public.anaira_create_public_booking(text,text,text,text,date,date,uuid,integer,integer,text) to anon,authenticated;

create or replace function public.anaira_enable_restaurant_store()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.plugin_code='restaurant-store' and new.enabled=true then
   insert into public.restaurant_storefronts(restaurant_id,slug,store_name,status,published)
   select r.id,coalesce(nullif(r.slug,''),lower(regexp_replace(coalesce(r.name,'restaurant'),'[^a-zA-Z0-9]+','-','g'))),coalesce(r.name,'Restaurant'),'published',true
   from public.restaurants r where r.id=new.restaurant_id
   on conflict (restaurant_id) do update set store_name=excluded.store_name;
 end if;
 return new;
end;
$$;
drop trigger if exists trg_enable_restaurant_store on public.restaurant_plugins;
create trigger trg_enable_restaurant_store after insert or update of enabled,plugin_code on public.restaurant_plugins for each row execute function public.anaira_enable_restaurant_store();
