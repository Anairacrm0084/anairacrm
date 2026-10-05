alter table public.hms_inventory add column if not exists stop_sell boolean not null default false;
alter table public.hms_inventory add column if not exists close_on_arrival boolean not null default false;
alter table public.hms_inventory add column if not exists close_on_departure boolean not null default false;
alter table public.hms_inventory add column if not exists cutoff_hours integer;
create index if not exists hms_inventory_smart_flow_idx on public.hms_inventory(restaurant_id,room_type_id,stay_date);
-- Runtime RPC: anaira_set_inventory_controls(restaurant_id,room_type_id,stay_date,stop_sell,close_on_arrival,close_on_departure,cutoff_hours)
