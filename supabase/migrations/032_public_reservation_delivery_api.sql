-- Public reservation and delivery checkout APIs. These are deliberately narrow RPCs.
create or replace function public.anaira_create_public_restaurant_reservation(
 p_slug text,p_guest_name text,p_guest_phone text,p_guest_email text,p_date date,p_time time,p_party_size integer,p_source text default 'direct'
) returns public.restaurant_reservations
language plpgsql security definer set search_path=public as $$
declare r public.restaurants; code text; rec public.restaurant_reservations;
begin
 select * into r from public.restaurants where slug=p_slug and status='active' limit 1;
 if r.id is null then raise exception 'Restaurant not found'; end if;
 code := 'ANR-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
 insert into public.restaurant_reservations(restaurant_id,reservation_code,guest_name,guest_phone,guest_email,reservation_date,reservation_time,party_size,status,source)
 values(r.id,code,p_guest_name,p_guest_phone,p_guest_email,p_date,p_time,p_party_size,'confirmed',p_source) returning * into rec;
 return rec;
end;
$$;

grant execute on function public.anaira_create_public_restaurant_reservation(text,text,text,text,date,time,integer,text) to anon,authenticated;

create or replace function public.anaira_create_public_delivery_order(
 p_slug text,p_customer_name text,p_customer_phone text,p_address jsonb,p_items jsonb,p_source text default 'anaira'
) returns public.delivery_orders
language plpgsql security definer set search_path=public as $$
declare r public.restaurants; code text; total numeric:=0; item jsonb; rec public.delivery_orders; oid uuid;
begin
 select * into r from public.restaurants where slug=p_slug and status='active' and delivery_enabled=true limit 1;
 if r.id is null then raise exception 'Delivery store not found or delivery is disabled'; end if;
 code := 'AND-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
 for item in select * from jsonb_array_elements(coalesce(p_items,'[]'::jsonb)) loop
   total := total + coalesce((item->>'unit_price')::numeric,0)*greatest(1,coalesce((item->>'quantity')::integer,1));
 end loop;
 insert into public.delivery_orders(restaurant_id,order_code,customer_name,customer_phone,address,source,status,payment_status,subtotal,total_amount)
 values(r.id,code,p_customer_name,p_customer_phone,coalesce(p_address,'{}'::jsonb),p_source,'placed','pending',total,total) returning * into rec;
 oid:=rec.id;
 for item in select * from jsonb_array_elements(coalesce(p_items,'[]'::jsonb)) loop
   insert into public.delivery_order_items(delivery_order_id,menu_item_id,name,quantity,unit_price,modifiers)
   values(oid,null,item->>'name',greatest(1,coalesce((item->>'quantity')::integer,1)),coalesce((item->>'unit_price')::numeric,0),coalesce(item->'modifiers','{}'::jsonb));
 end loop;
 return rec;
end;
$$;

grant execute on function public.anaira_create_public_delivery_order(text,text,text,jsonb,jsonb,text) to anon,authenticated;
