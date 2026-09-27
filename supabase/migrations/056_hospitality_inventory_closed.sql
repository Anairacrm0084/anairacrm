alter table public.hms_inventory
  add column if not exists closed boolean not null default false;
create unique index if not exists hms_inventory_restaurant_room_date_uq
  on public.hms_inventory(restaurant_id, room_type_id, stay_date);
