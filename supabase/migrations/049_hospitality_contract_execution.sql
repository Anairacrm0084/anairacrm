-- 049_hospitality_contract_execution.sql
-- Completes booking -> PMS + CRM integration without moving operational ownership.

create or replace function public.anaira_create_public_booking_by_id(
  p_restaurant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,
  p_check_in date,p_check_out date,p_room_type_id uuid,p_adults integer,
  p_children integer default 0,p_source text default 'anaira_marketplace'
) returns public.booking_reservations
language plpgsql security definer set search_path=public as $$
declare
  r public.restaurants; rt public.booking_room_types; rec public.booking_reservations;
  cid uuid; code text; nights integer; available integer; inventory_days integer;
  pms_id uuid;
begin
  select * into r from public.restaurants where id=p_restaurant_id and status='active';
  if r.id is null then raise exception 'Property not found'; end if;
  if not exists(select 1 from public.anaira_marketplace_listings where restaurant_id=p_restaurant_id and marketplace_visible=true and approval_status='approved' and hotel_booking_enabled=true) then raise exception 'Hotel booking is not enabled for this property'; end if;
  if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
  select * into rt from public.booking_room_types where id=p_room_type_id and restaurant_id=p_restaurant_id and active=true;
  if rt.id is null then raise exception 'Room type not found'; end if;

  select count(*),coalesce(min(total_rooms-booked_rooms-held_rooms),0)
    into inventory_days,available
  from public.booking_inventory
  where room_type_id=rt.id and stay_date>=p_check_in and stay_date<p_check_out and closed=false;
  if inventory_days <> (p_check_out-p_check_in) then raise exception 'Room inventory is not configured for all selected dates'; end if;
  if available<=0 then raise exception 'No room inventory available for the selected dates'; end if;

  nights:=p_check_out-p_check_in;
  cid:=public.anaira_resolve_crm_customer(p_restaurant_id,p_guest_name,p_guest_phone,p_guest_email);
  code:='ANB-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));

  insert into public.booking_reservations(
    restaurant_id,booking_code,customer_id,room_type_id,check_in,check_out,adults,children,
    guest_name,guest_phone,guest_email,status,payment_status,total_amount,source
  ) values(
    p_restaurant_id,code,cid,rt.id,p_check_in,p_check_out,p_adults,p_children,
    p_guest_name,p_guest_phone,p_guest_email,'pending','unpaid',rt.base_rate*nights,p_source
  ) returning * into rec;

  update public.booking_inventory
  set booked_rooms=booked_rooms+1
  where room_type_id=rt.id and stay_date>=p_check_in and stay_date<p_check_out and closed=false;

  insert into public.pms_reservations(
    restaurant_id,booking_code,guest_name,guest_phone,check_in,check_out,status,source,total_amount,metadata
  ) values(
    p_restaurant_id,rec.booking_code,p_guest_name,p_guest_phone,p_check_in,p_check_out,
    'reserved','anaira-booking-engine',rec.total_amount,
    jsonb_build_object('booking_reservation_id',rec.id,'customer_id',cid,'room_type_id',rt.id)
  ) returning id into pms_id;

  insert into public.anaira_integration_links(
    tenant_id,source_system,source_entity,source_id,target_system,target_entity,target_id
  ) values(p_restaurant_id,'hotel-booking','booking',rec.id,'hotel-pms','reservation',pms_id)
  on conflict do nothing;

  insert into public.crm_interactions(customer_id,channel,interaction_type,subject,notes)
  values(cid,'booking_engine','hotel_booking','New hotel booking',
    jsonb_build_object('booking_id',rec.id,'booking_code',rec.booking_code,'pms_reservation_id',pms_id)::text);

  insert into public.anaira_platform_events(restaurant_id,event_name,source_plugin,aggregate_type,aggregate_id,payload)
  values
   (p_restaurant_id,'booking.created','hotel-booking','booking',rec.id,jsonb_build_object('booking_id',rec.id,'booking_code',rec.booking_code,'customer_id',cid,'room_type_id',rt.id,'check_in',p_check_in,'check_out',p_check_out,'pms_reservation_id',pms_id)),
   (p_restaurant_id,'crm.customer.booking_created','hotel-booking','customer',cid,jsonb_build_object('booking_id',rec.id,'booking_code',rec.booking_code)),
   (p_restaurant_id,'payment.authorization_required','hotel-booking','booking',rec.id,jsonb_build_object('amount',rec.total_amount,'currency','INR'));
  return rec;
end;
$$;

-- Seed marketplace listings as pending for existing businesses. Super Admin approval is required.
insert into public.anaira_marketplace_listings(restaurant_id,listing_type,display_name,approval_status)
select r.id,
  case when coalesce(r.name,'') ilike '%hotel%' then 'hotel' else 'hotel_restaurant' end,
  r.name,'pending'
from public.restaurants r
where not exists(select 1 from public.anaira_marketplace_listings l where l.restaurant_id=r.id);

grant execute on function public.anaira_create_public_booking_by_id(uuid,text,text,text,date,date,uuid,integer,integer,text) to anon,authenticated;
