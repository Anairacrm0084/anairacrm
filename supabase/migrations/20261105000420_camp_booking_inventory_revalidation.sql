-- Safe Property Admin recovery for expired camping booking holds.
-- Creates a temporary hold only; approval is still a separate action.
create or replace function public.anaira_admin_revalidate_camp_booking_inventory(
  p_reservation_id uuid,
  p_ttl_minutes integer default 15
) returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  v_user uuid := auth.uid();
  r public.camp_reservations%rowtype;
  h public.camp_inventory_holds%rowtype;
  tx public.camp_booking_transactions%rowtype;
  d date;
  v_available integer;
  v_hold_id uuid := gen_random_uuid();
  v_ttl integer := greatest(5,least(coalesce(p_ttl_minutes,15),60));
  v_expiry timestamptz := now() + make_interval(mins => v_ttl);
begin
  if v_user is null then raise exception 'Authentication required'; end if;

  select * into r
    from public.camp_reservations
   where id=p_reservation_id
   for update;
  if not found then raise exception 'Camping reservation not found'; end if;

  if not exists (
    select 1 from public.profiles p
     where p.id=v_user and p.status='active'
       and (p.is_super_admin=true or (p.restaurant_id=r.restaurant_id and p.role='admin'))
  ) then
    raise exception 'Not authorized for this property';
  end if;

  if lower(coalesce(r.status,'')) not in ('payment_pending','pending','pending_approval','expired') then
    raise exception 'Only pending or expired camping bookings can be revalidated (current status: %)',r.status;
  end if;
  if lower(coalesce(r.payment_status,'pending')) in ('paid','refunded') then
    raise exception 'A paid or refunded booking cannot be recovered';
  end if;
  if r.check_in is null or r.check_out is null or r.check_out<=r.check_in then
    raise exception 'Camping booking dates are invalid';
  end if;
  if r.check_in<current_date then
    raise exception 'The camping check-in date has already passed';
  end if;

  select * into tx from public.camp_booking_transactions
   where reservation_id=r.id and restaurant_id=r.restaurant_id
   order by created_at desc limit 1 for update;

  -- Reuse a still-valid hold; do not double-count its held units.
  select * into h from public.camp_inventory_holds
   where reservation_id=r.id and restaurant_id=r.restaurant_id
     and status='held' and (expires_at is null or expires_at>now())
   order by created_at desc limit 1 for update;
  if found then
    return jsonb_build_object('ok',true,'reused',true,'hold_id',h.id,
      'status','held','expires_at',h.expires_at,'reservation_id',r.id,
      'approved',false,'sold_inventory_changed',false);
  end if;

  -- Release stale held rows first, including their per-night held_units.
  for h in
    select * from public.camp_inventory_holds
     where reservation_id=r.id and restaurant_id=r.restaurant_id and status='held'
     for update
  loop
    for d in select generate_series(h.check_in,h.check_out-1,interval '1 day')::date loop
      update public.camp_inventory
         set held_units=greatest(0,held_units-h.units)
       where restaurant_id=r.restaurant_id and unit_type_id=h.unit_type_id and stay_date=d;
    end loop;
    update public.camp_inventory_holds set status='expired' where id=h.id;
  end loop;

  -- Lock and validate every requested night before reserving any capacity.
  for d in select generate_series(r.check_in,r.check_out-1,interval '1 day')::date loop
    select greatest(0,total_units-sold_units-held_units-blocked_units)
      into v_available
      from public.camp_inventory
     where restaurant_id=r.restaurant_id and unit_type_id=r.unit_type_id and stay_date=d
     for update;
    if not found then
      raise exception 'Camping inventory is not configured for %',d;
    end if;
    if coalesce(v_available,0)<1 then
      raise exception 'Camping unit is no longer available for %',d;
    end if;
  end loop;

  insert into public.camp_inventory_holds(
    id,reservation_id,restaurant_id,unit_type_id,check_in,check_out,
    units,status,idempotency_key,expires_at
  ) values (
    v_hold_id,r.id,r.restaurant_id,r.unit_type_id,r.check_in,r.check_out,
    1,'held','admin-revalidate:'||r.id::text||':'||gen_random_uuid()::text,v_expiry
  );

  for d in select generate_series(r.check_in,r.check_out-1,interval '1 day')::date loop
    update public.camp_inventory
       set held_units=held_units+1
     where restaurant_id=r.restaurant_id and unit_type_id=r.unit_type_id and stay_date=d;
  end loop;

  update public.camp_reservations
     set status='payment_pending',updated_at=now()
   where id=r.id and restaurant_id=r.restaurant_id;
  if tx.id is not null then
    update public.camp_booking_transactions
       set inventory_hold_id=v_hold_id,state='payment_pending',updated_at=now(),
           payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object(
             'inventory_hold_id',v_hold_id,
             'inventory_hold_revalidated_at',now(),
             'inventory_hold_expires_at',v_expiry
           )
     where id=tx.id;
  end if;

  return jsonb_build_object('ok',true,'reused',false,'hold_id',v_hold_id,
    'status','held','expires_at',v_expiry,'reservation_id',r.id,
    'approved',false,'sold_inventory_changed',false);
end;
$$;

revoke all on function public.anaira_admin_revalidate_camp_booking_inventory(uuid,integer) from public,anon;
grant execute on function public.anaira_admin_revalidate_camp_booking_inventory(uuid,integer) to authenticated;
