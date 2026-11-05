-- Booking Engine control-center closure: commit hotel holds only on approval,
-- keep payment collection available after confirmation, and ledger camp payments.
create or replace function public.anaira_hotel_confirm_reservation(
  p_restaurant_id uuid,
  p_reservation_id uuid,
  p_user_id uuid default auth.uid()
) returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  r public.hms_reservations%rowtype;
  tx public.crm_booking_transactions%rowtype;
  h public.anaira_hotel_inventory_holds%rowtype;
  inv public.hms_inventory%rowtype;
  d date;
  held integer;
  blocked_physical integer;
  available integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not (p_restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) then
    raise exception 'Tenant access denied';
  end if;

  select * into r from public.hms_reservations
   where id=p_reservation_id and restaurant_id=p_restaurant_id for update;
  if not found then raise exception 'Reservation not found'; end if;
  if r.status in ('cancelled','no_show','checked_out') then
    raise exception 'Reservation cannot be confirmed from status %',r.status;
  end if;
  if r.room_type_id is null then raise exception 'Room type is required before confirming this reservation'; end if;

  select * into tx from public.crm_booking_transactions
   where tenant_id=p_restaurant_id and booking_id=r.id
   order by created_at desc limit 1 for update;

  if tx.id is not null and tx.inventory_hold_id is not null then
    select * into h from public.anaira_hotel_inventory_holds
     where id=tx.inventory_hold_id and restaurant_id=p_restaurant_id for update;
    if not found then raise exception 'The booking inventory hold is missing; refresh availability before approval'; end if;
    if h.status='held' then
      if h.expires_at is not null and h.expires_at<now() then
        raise exception 'The booking inventory hold expired; refresh availability before approval';
      end if;
      perform public.anaira_phase13_hotel_inventory_hold_release(p_restaurant_id,h.id,'consume');
      h.status:='consumed';
    elsif h.status not in ('consumed') then
      raise exception 'The booking inventory hold is no longer active (%); refresh availability',h.status;
    end if;
  else
    select * into h from public.anaira_hotel_inventory_holds
     where restaurant_id=p_restaurant_id and reservation_id=r.id
       and status='held' order by created_at desc limit 1 for update;
    if found then
      if h.expires_at is not null and h.expires_at<now() then
        raise exception 'The booking inventory hold expired; refresh availability before approval';
      end if;
      perform public.anaira_phase13_hotel_inventory_hold_release(p_restaurant_id,h.id,'consume');
      h.status:='consumed';
    elsif r.status<>'confirmed' then
    -- Front-desk/manual reservations without a checkout hold must still respect
    -- other live holds before they can be confirmed.
    for d in select generate_series(r.check_in,r.check_out-1,interval '1 day')::date loop
      select * into inv from public.hms_inventory
       where restaurant_id=p_restaurant_id and room_type_id=r.room_type_id and stay_date=d for update;
      if not found then
        insert into public.hms_inventory(restaurant_id,room_type_id,stay_date,total_rooms,sold_rooms,blocked_rooms,closed)
        select p_restaurant_id,r.room_type_id,d,count(*)::int,0,0,false
          from public.hms_rooms where restaurant_id=p_restaurant_id and room_type_id=r.room_type_id
            and active=true and status not in ('maintenance','out_of_order','blocked');
        select * into inv from public.hms_inventory
         where restaurant_id=p_restaurant_id and room_type_id=r.room_type_id and stay_date=d for update;
      end if;
      if coalesce(inv.closed,false) or coalesce(inv.stop_sell,false) then
        raise exception 'Inventory is closed for %',d;
      end if;
      select count(*)::int into blocked_physical
       from public.hms_room_inventory_blocks b
       join public.hms_rooms rm on rm.id=b.room_id
       where b.restaurant_id=p_restaurant_id and b.stay_date=d and b.active
         and rm.room_type_id=r.room_type_id;
      select coalesce(sum(x.rooms),0)::int into held
       from public.anaira_hotel_inventory_holds x
       where x.restaurant_id=p_restaurant_id and x.room_type_id=r.room_type_id
         and x.check_in<=d and x.check_out>d and x.status='held'
         and (x.expires_at is null or x.expires_at>now());
      available:=greatest(0,coalesce(inv.total_rooms,0)-coalesce(inv.sold_rooms,0)
        -coalesce(inv.blocked_rooms,0)-coalesce(blocked_physical,0)-coalesce(held,0));
      if available<1 then raise exception 'Hotel inventory unavailable for %',d; end if;
    end loop;
    end if;
  end if;

  if r.status<>'confirmed' then
    update public.hms_reservations
     set status='confirmed',
         payment_status=coalesce(payment_status,'pending'),
         balance_amount=greatest(coalesce(total_amount,0)-coalesce(paid_amount,0),0),
         updated_at=now()
     where id=r.id;
    insert into public.hms_reservation_events
      (restaurant_id,reservation_id,from_status,to_status,event_type,notes,actor_user_id)
    values (p_restaurant_id,r.id,r.status,'confirmed','admin_confirm',
      'Confirmed from Booking Engine Reservation Control Center',p_user_id);
  end if;

  perform public.anaira_reconcile_hotel_inventory(p_restaurant_id,r.room_type_id,r.check_in,r.check_out);
  if tx.id is not null then
    update public.crm_booking_transactions set state='confirmed',updated_at=now()
     where id=tx.id and state not in ('paid','refunded','cancelled');
  end if;
  return jsonb_build_object('ok',true,'reservation_id',r.id,'status','confirmed',
    'inventory_hold_status',case when h.id is not null then h.status else 'not_required' end);
end;
$$;

revoke all on function public.anaira_hotel_confirm_reservation(uuid,uuid,uuid) from public,anon;
grant execute on function public.anaira_hotel_confirm_reservation(uuid,uuid,uuid) to authenticated;

create or replace function public.anaira_admin_record_camp_payment(
  p_reservation_id uuid,
  p_amount numeric,
  p_method text,
  p_reference text default null,
  p_proof_url text default null,
  p_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  actor uuid:=auth.uid();
  c public.camp_reservations%rowtype;
  hr public.hms_reservations%rowtype;
  f public.hms_folios%rowtype;
  payment_id uuid;
  paid numeric;
  due numeric;
  next_status text;
begin
  if actor is null then raise exception 'Authentication required'; end if;
  if p_amount is null or p_amount<=0 then raise exception 'Payment amount must be greater than zero'; end if;
  if p_method not in ('cash','card','upi','bank_transfer','qr_upi','pay_at_camp','pay_at_hotel') then
    raise exception 'Invalid payment method';
  end if;

  select * into c from public.camp_reservations where id=p_reservation_id for update;
  if not found then raise exception 'Camping reservation not found'; end if;
  if not exists(select 1 from public.profiles p where p.id=actor and p.status='active'
    and (p.is_super_admin=true or (p.restaurant_id=c.restaurant_id and p.role='admin'))) then
    raise exception 'Not authorized for this property';
  end if;
  if c.status<>'confirmed' or c.hms_reservation_id is null then
    raise exception 'Approve the camping reservation before collecting payment';
  end if;

  select * into hr from public.hms_reservations
   where id=c.hms_reservation_id and restaurant_id=c.restaurant_id for update;
  if not found then raise exception 'Linked HMS reservation not found'; end if;
  due:=greatest(coalesce(c.total_amount,0)-coalesce(c.paid_amount,0),0);
  if p_amount>due then raise exception 'Payment exceeds outstanding balance'; end if;
  if due<=0 then return jsonb_build_object('ok',true,'already_paid',true,'balance_amount',0); end if;

  select * into f from public.hms_folios
   where restaurant_id=c.restaurant_id and reservation_id=hr.id
   order by created_at desc limit 1 for update;

  insert into public.hms_payments
   (restaurant_id,folio_id,reservation_id,guest_id,method,provider,amount,reference,status,proof_url,notes,settled_at)
  values
   (c.restaurant_id,f.id,hr.id,hr.guest_id,p_method,'camp',p_amount,p_reference,'paid',p_proof_url,p_notes,now())
  returning id into payment_id;

  paid:=coalesce(c.paid_amount,0)+p_amount;
  due:=greatest(coalesce(c.total_amount,0)-paid,0);
  next_status:=case when due<=0 then 'paid' when paid>0 then 'partial' else 'pending' end;

  update public.camp_reservations
   set paid_amount=paid,balance_amount=due,payment_status=next_status,
       payment_method=p_method,payment_reference=p_reference,
       payment_proof_url=coalesce(p_proof_url,payment_proof_url),updated_at=now()
   where id=c.id;

  update public.hms_reservations
   set paid_amount=paid,balance_amount=due,payment_status=next_status,
       payment_method=p_method,payment_reference=p_reference,
       payment_proof_url=coalesce(p_proof_url,payment_proof_url),
       payment_verified_at=now(),updated_at=now()
   where id=hr.id;

  if f.id is not null then
    update public.hms_folios set paid_amount=paid,balance=due,updated_at=now() where id=f.id;
  end if;

  update public.camp_booking_transactions
   set state=case when due<=0 then 'paid' else 'partially_paid' end,updated_at=now(),
       payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object(
         'last_payment_id',payment_id,'last_payment_amount',p_amount,
         'payment_method',p_method,'payment_reference',p_reference)
   where reservation_id=c.id;

  return jsonb_build_object('ok',true,'payment_id',payment_id,'paid_amount',paid,
    'balance_amount',due,'payment_status',next_status,'hms_reservation_id',hr.id);
end;
$$;

revoke all on function public.anaira_admin_record_camp_payment(uuid,numeric,text,text,text,text) from public,anon;
grant execute on function public.anaira_admin_record_camp_payment(uuid,numeric,text,text,text,text) to authenticated;
