-- ANAIRA: repair existing HMS rows for properties explicitly configured as CAMPING ONLY.
-- No rows are deleted. Existing canonical records that were saved with the default
-- Hotel hospitality type are reclassified as Camping so they remain visible in the
-- Camping management/store context.
update public.hms_settings hs
set hospitality_type='camp',
    unit_label_singular='Camp / Tent',
    unit_label_plural='Camps / Tents',
    updated_at=now()
where hs.restaurant_id in (
  select r.id from public.restaurants r
  where array_length(r.hospitality_types,1)=1
    and r.hospitality_types[1]='camp'
);

update public.hms_room_types h
set hospitality_type='camp'
where h.restaurant_id in (
  select r.id from public.restaurants r
  where array_length(r.hospitality_types,1)=1
    and r.hospitality_types[1]='camp'
)
and coalesce(h.hospitality_type,'hotel')='hotel';

update public.hms_rate_plans rp
set hospitality_type='camp',
    pricing_mode=coalesce(rp.pricing_mode,'per_person')
where rp.restaurant_id in (
  select r.id from public.restaurants r
  where array_length(r.hospitality_types,1)=1
    and r.hospitality_types[1]='camp'
)
and coalesce(rp.hospitality_type,'hotel')='hotel';

update public.hms_rooms hr
set hospitality_type='camp'
where hr.restaurant_id in (
  select r.id from public.restaurants r
  where array_length(r.hospitality_types,1)=1
    and r.hospitality_types[1]='camp'
)
and coalesce(hr.hospitality_type,'hotel')='hotel';

update public.hms_reservations hr
set hospitality_type='camp'
where hr.restaurant_id in (
  select r.id from public.restaurants r
  where array_length(r.hospitality_types,1)=1
    and r.hospitality_types[1]='camp'
)
and coalesce(hr.hospitality_type,'hotel')='hotel';

create index if not exists hms_room_types_restaurant_hospitality_idx
on public.hms_room_types(restaurant_id,hospitality_type,active);

create index if not exists hms_rate_plans_restaurant_hospitality_idx
on public.hms_rate_plans(restaurant_id,hospitality_type,active);
