-- Anaira Camping Admin Approval + HMS link
-- Run after reviewing the migration. Does not auto-approve existing reservations.
alter table public.camp_reservations
  add column if not exists hms_reservation_id uuid references public.hms_reservations(id) on delete set null,
  add column if not exists approved_by uuid references auth.users(id) on delete set null,
  add column if not exists approved_at timestamptz,
  add column if not exists admin_notes text;

create index if not exists camp_reservations_hms_reservation_id_idx
  on public.camp_reservations(hms_reservation_id) where hms_reservation_id is not null;

create or replace function public.anaira_admin_manage_camp_reservation(
  p_reservation_id uuid,
  p_action text,
  p_payment_method text default 'pay_at_camp',
  p_payment_reference text default null,
  p_payment_verified boolean default false,
  p_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  r public.camp_reservations%rowtype;
  h public.camp_inventory_holds%rowtype;
  v_guest_id uuid;
  v_hms_id uuid;
  v_folio_id uuid;
  v_property_id uuid;
  d date;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_action not in ('approve','verify_payment','reject') then raise exception 'Unsupported action'; end if;
  select * into r from public.camp_reservations where id=p_reservation_id for update;
  if not found then raise exception 'Camping reservation not found'; end if;
  if not exists (
    select 1 from public.profiles p
    where p.id=v_user and p.status='active'
      and (p.is_super_admin=true or (p.restaurant_id=r.restaurant_id and p.role='admin'))
  ) then raise exception 'Not authorized for this property'; end if;

  if p_action='reject' then
    if r.status='confirmed' then raise exception 'Use cancellation workflow for confirmed bookings'; end if;
    select * into h from public.camp_inventory_holds
      where reservation_id=r.id and status='held'
      order by created_at desc limit 1 for update;
    if found then
      for d in select generate_series(h.check_in,h.check_out-1,interval '1 day')::date loop
        update public.camp_inventory set held_units=greatest(0,held_units-h.units)
        where restaurant_id=r.restaurant_id and unit_type_id=h.unit_type_id and stay_date=d;
      end loop;
      update public.camp_inventory_holds set status='released' where id=h.id;
    end if;
    update public.camp_reservations set status='cancelled',approved_by=v_user,approved_at=now(),
      admin_notes=coalesce(p_notes,admin_notes),updated_at=now() where id=r.id;
    update public.camp_booking_transactions set state='rejected',updated_at=now()
      where reservation_id=r.id and state in ('payment_pending','payment_proof_submitted');
    return jsonb_build_object('ok',true,'action','reject','reservation_id',r.id,'status','cancelled');
  end if;

  if p_action='approve' then
    if r.status='confirmed' and r.hms_reservation_id is not null then
      return jsonb_build_object('ok',true,'already_approved',true,'hms_reservation_id',r.hms_reservation_id);
    end if;
    if r.status<>'payment_pending' then raise exception 'Only payment-pending bookings can be approved'; end if;
    if p_payment_method not in ('pay_at_camp','pay_at_hotel','bank_transfer','qr_upi') then raise exception 'Invalid payment method'; end if;
    if p_payment_verified and p_payment_method in ('bank_transfer','qr_upi')
       and nullif(trim(coalesce(p_payment_reference,r.payment_reference,'')),'') is null
       and r.payment_proof_url is null then raise exception 'Payment reference or proof is required'; end if;

    select * into h from public.camp_inventory_holds
      where reservation_id=r.id and status='held'
      order by created_at desc limit 1 for update;
    if not found then raise exception 'Inventory hold missing; recheck availability and create a new booking hold'; end if;
    if h.expires_at<now() then raise exception 'Inventory hold expired; recheck availability'; end if;

    for d in select generate_series(r.check_in,r.check_out-1,interval '1 day')::date loop
      update public.camp_inventory set held_units=greatest(0,held_units-h.units),sold_units=sold_units+h.units
      where restaurant_id=r.restaurant_id and unit_type_id=r.unit_type_id and stay_date=d
        and total_units-sold_units-blocked_units>=h.units;
      if not found then raise exception 'Inventory changed for %; refresh availability',d; end if;
    end loop;
    update public.camp_inventory_holds set status='consumed' where id=h.id;

    select id into v_guest_id from public.hms_guests
      where restaurant_id=r.restaurant_id and
      ((r.guest_phone is not null and phone=r.guest_phone) or
       (r.guest_email is not null and lower(email)=lower(r.guest_email)))
      order by created_at desc limit 1;
    if v_guest_id is null then
      insert into public.hms_guests(restaurant_id,full_name,phone,email)
      values(r.restaurant_id,r.guest_name,r.guest_phone,r.guest_email) returning id into v_guest_id;
    end if;

    select id into v_property_id from public.anaira_hospitality_properties_master
      where tenant_id=r.restaurant_id and source_table='restaurants'
        and source_id=r.restaurant_id and property_type='camp' and active
      order by created_at desc limit 1;

    insert into public.hms_reservations(
      restaurant_id,reservation_code,booking_reference,guest_id,source,status,check_in,check_out,
      adults,children,rate,total_amount,notes,booking_engine_reservation_id,deposit_amount,
      paid_amount,balance_amount,payment_status,payment_method,payment_reference,
      payment_proof_url,payment_verified_at,hospitality_type,pricing_mode,guest_count,property_id,
      special_requests
    ) values (
      r.restaurant_id,r.reservation_code||'-CAMP',r.reservation_code,v_guest_id,
      'camping_booking_engine','confirmed',r.check_in,r.check_out,r.adults,r.children,
      r.nightly_rate,r.total_amount,coalesce(p_notes,'Camping booking approved in Booking Engine'),
      r.id,0,case when p_payment_verified then r.total_amount else 0 end,
      case when p_payment_verified then 0 else r.total_amount end,
      case when p_payment_verified then 'paid' else 'pending' end,
      p_payment_method,coalesce(p_payment_reference,r.payment_reference),r.payment_proof_url,
      case when p_payment_verified then now() else null end,'camp',r.pricing_mode,
      r.adults+r.children,v_property_id,
      jsonb_build_array(jsonb_build_object('camp_unit_type_id',r.unit_type_id,'camp_rate_plan_id',r.rate_plan_id))
    ) on conflict (restaurant_id,reservation_code) do nothing returning id into v_hms_id;

    if v_hms_id is null then
      select id into v_hms_id from public.hms_reservations
      where restaurant_id=r.restaurant_id and reservation_code=r.reservation_code||'-CAMP' limit 1;
    end if;
    if v_hms_id is null then raise exception 'HMS reservation link could not be created'; end if;

    select id into v_folio_id from public.hms_folios where restaurant_id=r.restaurant_id and reservation_id=v_hms_id limit 1;
    if v_folio_id is null then
      insert into public.hms_folios(restaurant_id,reservation_id,guest_id,status,subtotal,tax,total,balance,paid_amount,deposit_amount)
      values(r.restaurant_id,v_hms_id,v_guest_id,'open',r.total_amount,0,r.total_amount,
        case when p_payment_verified then 0 else r.total_amount end,
        case when p_payment_verified then r.total_amount else 0 end,0) returning id into v_folio_id;
    end if;

    update public.camp_reservations set status='confirmed',
      payment_status=case when p_payment_verified then 'paid' else 'pending' end,
      payment_method=p_payment_method,payment_reference=coalesce(p_payment_reference,payment_reference),
      paid_amount=case when p_payment_verified then total_amount else 0 end,
      balance_amount=case when p_payment_verified then 0 else total_amount end,
      hms_reservation_id=v_hms_id,approved_by=v_user,approved_at=now(),
      admin_notes=coalesce(p_notes,admin_notes),updated_at=now() where id=r.id;
    update public.camp_booking_transactions set state=case when p_payment_verified then 'paid' else 'confirmed' end,
      updated_at=now(),payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('admin_action','approve','hms_reservation_id',v_hms_id)
      where reservation_id=r.id;
    return jsonb_build_object('ok',true,'action','approve','reservation_id',r.id,
      'hms_reservation_id',v_hms_id,'folio_id',v_folio_id,'status','confirmed',
      'payment_status',case when p_payment_verified then 'paid' else 'pending' end);
  end if;

  if p_action='verify_payment' then
    if r.status<>'confirmed' or r.hms_reservation_id is null then raise exception 'Approve booking before verifying payment'; end if;
    if r.payment_status='paid' then return jsonb_build_object('ok',true,'already_paid',true); end if;
    if r.payment_method in ('bank_transfer','qr_upi') and
       nullif(trim(coalesce(p_payment_reference,r.payment_reference,'')),'') is null and r.payment_proof_url is null
       then raise exception 'Payment reference or proof is required'; end if;
    update public.camp_reservations set payment_status='paid',paid_amount=total_amount,balance_amount=0,
      payment_reference=coalesce(p_payment_reference,payment_reference),approved_by=v_user,
      approved_at=coalesce(approved_at,now()),admin_notes=coalesce(p_notes,admin_notes),updated_at=now()
      where id=r.id;
    update public.hms_reservations set payment_status='paid',paid_amount=total_amount,balance_amount=0,
      payment_reference=coalesce(p_payment_reference,payment_reference),payment_verified_at=now(),
      payment_notes=coalesce(p_notes,payment_notes),updated_at=now()
      where id=r.hms_reservation_id and restaurant_id=r.restaurant_id;
    update public.hms_folios set paid_amount=total,balance=0,updated_at=now()
      where reservation_id=r.hms_reservation_id and restaurant_id=r.restaurant_id;
    update public.camp_booking_transactions set state='paid',updated_at=now()
      where reservation_id=r.id;
    return jsonb_build_object('ok',true,'action','verify_payment','reservation_id',r.id,'payment_status','paid');
  end if;
end;
$$;

revoke all on function public.anaira_admin_manage_camp_reservation(uuid,text,text,text,boolean,text) from public,anon;
grant execute on function public.anaira_admin_manage_camp_reservation(uuid,text,text,text,boolean,text) to authenticated;
