-- hms_reservations already has trg_hms_reservations_inventory_sync, which
-- recalculates sold_rooms from canonical confirmed reservations. Remove the
-- duplicate manual increment to avoid counting OTA imports twice.
do $migration$
declare
  v_definition text;
  v_needle text := $needle$
  for v_day in select generate_series(v_inbox.check_in,v_inbox.check_out-1,interval '1 day')::date loop
    update public.hms_inventory set sold_rooms=sold_rooms+1,updated_at=now()
    where restaurant_id=p_restaurant_id and room_type_id=v_inbox.room_type_id and stay_date=v_day;
  end loop;
$needle$;
begin
  v_definition := pg_get_functiondef('public.anaira_process_ota_reservation(uuid,uuid,text)'::regprocedure);
  if position(v_needle in v_definition)=0 then
    raise exception 'Expected manual inventory increment block was not found; refusing to alter function';
  end if;
  v_definition := replace(v_definition,v_needle,'');
  execute v_definition;
end
$migration$;
