-- Idempotent data sync for Home By (Justin).
-- Keeps source HMS rows intact and copies the existing room/rate/inventory
-- catalogue into the canonical Anaira Stay booking tables.

DO $$
DECLARE
  v_property_id uuid := 'd6e10502-c7c8-4375-9245-48fab78f41ec';
  v_restaurant_id uuid := '9756be82-0c27-40a9-bd86-586a9f805e6c';
  v_type_count int;
  v_rate_count int;
  v_inventory_count int;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.anaira_stay_properties
    WHERE id=v_property_id AND restaurant_id=v_restaurant_id
      AND stay_type='homestay' AND active=true
  ) THEN
    RAISE EXCEPTION 'Expected active Homestay property was not found; migration stopped.';
  END IF;

  INSERT INTO public.anaira_stay_unit_types
    (id,restaurant_id,property_id,name,code,description,max_guests,max_adults,max_children,
     unit_count,base_rate,image_urls,amenities,active,created_at,updated_at)
  SELECT rt.id,rt.restaurant_id,v_property_id,rt.name,rt.code,
    COALESCE(rt.short_description,rt.description),
    GREATEST(1,COALESCE(rt.max_guests,rt.max_adults+rt.max_children,rt.max_adults,1)),
    GREATEST(1,COALESCE(rt.max_adults,1)),GREATEST(0,COALESCE(rt.max_children,0)),
    GREATEST(0,COALESCE(inv.units,1)),GREATEST(0,COALESCE(rt.base_rate,0)),
    COALESCE(rt.image_urls,'[]'::jsonb),COALESCE(rt.amenities,'[]'::jsonb),
    rt.active,COALESCE(rt.created_at,now()),now()
  FROM public.hms_room_types rt
  LEFT JOIN LATERAL (
    SELECT max(hi.total_rooms)::int AS units FROM public.hms_inventory hi
    WHERE hi.restaurant_id=rt.restaurant_id AND hi.room_type_id=rt.id
  ) inv ON true
  WHERE rt.restaurant_id=v_restaurant_id AND COALESCE(rt.hospitality_type,'hotel')='homestay'
  ON CONFLICT (id) DO UPDATE SET
    restaurant_id=EXCLUDED.restaurant_id,property_id=EXCLUDED.property_id,
    name=EXCLUDED.name,code=EXCLUDED.code,description=EXCLUDED.description,
    max_guests=EXCLUDED.max_guests,max_adults=EXCLUDED.max_adults,
    max_children=EXCLUDED.max_children,unit_count=EXCLUDED.unit_count,
    base_rate=EXCLUDED.base_rate,image_urls=EXCLUDED.image_urls,
    amenities=EXCLUDED.amenities,active=EXCLUDED.active,updated_at=now();

  INSERT INTO public.anaira_stay_rate_plans
    (id,restaurant_id,unit_type_id,name,code,pricing_mode,rate,weekend_rate,
     seasonal_multiplier,refundable,deposit_percent,cancellation_policy,min_stay,
     max_stay,active,created_at,updated_at)
  SELECT rp.id,rp.restaurant_id,rp.room_type_id,rp.name,rp.code,
    CASE WHEN rp.pricing_mode IN ('per_person','per_unit') THEN rp.pricing_mode ELSE 'per_unit' END,
    GREATEST(0,rp.rate),NULLIF(rp.weekend_rate,0),
    GREATEST(0.0001,COALESCE(rp.seasonal_multiplier,1)),
    COALESCE(rp.refundable,true),COALESCE(rp.deposit_percent,0),
    rp.cancellation_policy,GREATEST(1,COALESCE(rp.min_stay,1)),
    rp.max_stay,rp.active,COALESCE(rp.created_at,now()),now()
  FROM public.hms_rate_plans rp
  JOIN public.anaira_stay_unit_types u ON u.id=rp.room_type_id AND u.restaurant_id=rp.restaurant_id
  WHERE rp.restaurant_id=v_restaurant_id AND COALESCE(rp.hospitality_type,'hotel')='homestay'
  ON CONFLICT (id) DO UPDATE SET
    restaurant_id=EXCLUDED.restaurant_id,unit_type_id=EXCLUDED.unit_type_id,
    name=EXCLUDED.name,code=EXCLUDED.code,pricing_mode=EXCLUDED.pricing_mode,
    rate=EXCLUDED.rate,weekend_rate=EXCLUDED.weekend_rate,
    seasonal_multiplier=EXCLUDED.seasonal_multiplier,refundable=EXCLUDED.refundable,
    deposit_percent=EXCLUDED.deposit_percent,cancellation_policy=EXCLUDED.cancellation_policy,
    min_stay=EXCLUDED.min_stay,max_stay=EXCLUDED.max_stay,active=EXCLUDED.active,updated_at=now();

  INSERT INTO public.anaira_stay_inventory
    (unit_type_id,restaurant_id,stay_date,total_units,sold_units,held_units,blocked_units,closed)
  SELECT hi.room_type_id,hi.restaurant_id,hi.stay_date,GREATEST(0,hi.total_rooms),
    GREATEST(0,hi.sold_rooms),0,GREATEST(0,hi.blocked_rooms),COALESCE(hi.closed,false)
  FROM public.hms_inventory hi
  JOIN public.anaira_stay_unit_types u ON u.id=hi.room_type_id AND u.restaurant_id=hi.restaurant_id
  WHERE hi.restaurant_id=v_restaurant_id
  ON CONFLICT (unit_type_id,stay_date) DO UPDATE SET
    total_units=EXCLUDED.total_units,sold_units=EXCLUDED.sold_units,
    blocked_units=EXCLUDED.blocked_units,closed=EXCLUDED.closed;

  SELECT count(*) INTO v_type_count FROM public.anaira_stay_unit_types
    WHERE restaurant_id=v_restaurant_id AND property_id=v_property_id AND active;
  SELECT count(*) INTO v_rate_count FROM public.anaira_stay_rate_plans
    WHERE restaurant_id=v_restaurant_id AND active;
  SELECT count(*) INTO v_inventory_count FROM public.anaira_stay_inventory
    WHERE restaurant_id=v_restaurant_id;
  IF v_type_count < 1 OR v_rate_count < 1 OR v_inventory_count < 1 THEN
    RAISE EXCEPTION 'Migration verification failed: units %, rates %, inventory %',
      v_type_count,v_rate_count,v_inventory_count;
  END IF;
END $$;
