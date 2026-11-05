-- Property Admin context + safe recovery for expired direct-hotel booking holds.
-- Revalidation creates a temporary hold only. It never confirms a reservation
-- and never increments sold inventory; approval remains a separate action.

create or replace function public.anaira_admin_revalidate_hotel_booking_inventory(
  p_restaurant_id uuid,
  p_reservation_id uuid,
  p_ttl_minutes integer default 15
) returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  actor uuid := auth.uid();
  r public.hms_reservations%rowtype;
  tx public.crm_booking_transactions%rowtype;
  h public.anaira_hotel_inventory_holds%rowtype;
  result jsonb;
  hold_id uuid;
  ttl integer := greatest(5,least(coalesce(p_ttl_minutes,15),60));
begin
  if actor is null then raise exception 'Authentication required'; end if;
  if p_restaurant_id is null or not (
    p_restaurant_id=public.anaira_current_restaurant_id()
    or public.anaira_current_is_super_admin()
  ) then
    raise exception 'Tenant access denied';
  end if;

  select * into r
    from public.hms_reservations
   where id=p_reservation_id and restaurant_id=p_restaurant_id
   for update;
  if not found then raise exception 'Reservation not found'; end if;
  if lower(coalesce(r.status,'')) not in ('inquiry','payment_pending','pending','pending_approval','expired') then
    raise exception 'Only a pending or expired booking can have its inventory hold revalidated (current status: %)',r.status;
  end if;
  if lower(coalesce(r.payment_status,'pending')) in ('paid','refunded') then
    raise exception 'A paid or refunded booking cannot be recovered through inventory revalidation';
  end if;
  if r.room_type_id is null then raise exception 'Room type is missing from this booking'; end if;
  if r.check_in is null or r.check_out is null or r.check_out<=r.check_in then
    raise exception 'Booking dates are invalid';
  end if;
  if r.check_in<current_date then raise exception 'The booking check-in date has already passed'; end if;

  select * into tx
    from public.crm_booking_transactions
   where tenant_id=p_restaurant_id and booking_id=r.id
   order by created_at desc
   limit 1
   for update;

  -- Reuse a still-valid hold instead of creating duplicate capacity claims.
  if tx.inventory_hold_id is not null then
    select * into h from public.anaira_hotel_inventory_holds
     where id=tx.inventory_hold_id and restaurant_id=p_restaurant_id
     for update;
    if found and h.status='held' and (h.expires_at is null or h.expires_at>now()) then
      return jsonb_build_object('ok',true,'reused',true,'hold_id',h.id,'status',h.status,'expires_at',h.expires_at,'reservation_id',r.id);
    end if;
  end if;

  -- The canonical hold function checks every night, sell rules, physical blocks,
  -- existing sold inventory and other unexpired holds under inventory row locks.
  result := public.anaira_phase13_hotel_inventory_hold(
    p_restaurant_id,
    r.room_type_id,
    r.check_in,
    r.check_out,
    1,
    'admin-revalidate:'||r.id::text||':'||gen_random_uuid()::text,
    r.id,
    ttl
  );
  hold_id := nullif(result->>'hold_id','')::uuid;
  if hold_id is null or coalesce(result->>'status','')<>'held' then
    raise exception 'A fresh inventory hold could not be created';
  end if;

  if lower(coalesce(r.status,''))='expired' then
    update public.hms_reservations set status='inquiry',updated_at=now() where id=r.id and restaurant_id=p_restaurant_id;
  end if;

  if tx.id is not null then
    update public.crm_booking_transactions
       set inventory_hold_id=hold_id,
           expires_at=(result->>'expires_at')::timestamptz,
           state=case when state in ('expired','failed','payment_pending') then 'payment_pending' else state end,
           payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object(
             'inventory_hold_id',hold_id,
             'inventory_hold_revalidated_at',now(),
             'inventory_hold_expires_at',result->>'expires_at'
           ),
           updated_at=now()
     where id=tx.id;
  end if;

  return jsonb_build_object(
    'ok',true,
    'reused',false,
    'hold_id',hold_id,
    'status','held',
    'expires_at',result->>'expires_at',
    'reservation_id',r.id,
    'approved',false,
    'sold_inventory_changed',false
  );
end;
$$;

revoke all on function public.anaira_admin_revalidate_hotel_booking_inventory(uuid,uuid,integer) from public,anon;
grant execute on function public.anaira_admin_revalidate_hotel_booking_inventory(uuid,uuid,integer) to authenticated;
