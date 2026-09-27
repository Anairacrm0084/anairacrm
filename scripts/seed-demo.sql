insert into public.crm_room_types (name,code,base_rate,min_rate,max_rate,max_occupancy)
values
('Deluxe Room','DLX',2500,2000,5000,2),
('Super Deluxe','SDLX',3500,2800,6500,3),
('Luxury Suite','LUX',4500,3500,9000,4)
on conflict do nothing;
