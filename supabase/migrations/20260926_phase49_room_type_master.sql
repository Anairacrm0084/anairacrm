-- Phase 49: professional Room Type master
alter table public.hms_room_types
  add constraint hms_room_types_base_rate_nonnegative_chk check (coalesce(base_rate,0) >= 0),
  add constraint hms_room_types_weekend_rate_nonnegative_chk check (coalesce(weekend_price,0) >= 0),
  add constraint hms_room_types_capacity_chk check (coalesce(max_adults,0) >= 1 and coalesce(max_children,0) >= 0),
  add constraint hms_room_types_beds_chk check (coalesce(number_of_beds,0) >= 1),
  add constraint hms_room_types_extra_adult_nonnegative_chk check (coalesce(extra_adult_price,0) >= 0),
  add constraint hms_room_types_extra_child_nonnegative_chk check (coalesce(extra_child_price,0) >= 0),
  add constraint hms_room_types_tax_chk check (coalesce(tax_percent,0) between 0 and 100);

create unique index if not exists hms_room_types_restaurant_code_uidx
  on public.hms_room_types(restaurant_id, lower(code))
  where code is not null and btrim(code) <> '';

create unique index if not exists hms_room_types_restaurant_name_uidx
  on public.hms_room_types(restaurant_id, lower(name));

create index if not exists hms_room_types_restaurant_active_idx
  on public.hms_room_types(restaurant_id, active, name);
