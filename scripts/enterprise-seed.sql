insert into public.crm_loyalty_tiers (name,min_lifetime_points,benefits)
values
('Bronze',0,'{"welcome":"standard"}'),
('Silver',1000,'{"discount_percent":5}'),
('Gold',5000,'{"discount_percent":10,"upgrade":"subject_to_availability"}'),
('Platinum',10000,'{"discount_percent":15,"priority":"vip"}'),
('VIP',25000,'{"dedicated_manager":true}')
on conflict do nothing;

insert into public.crm_pricing_rules
(name,rule_type,priority,min_occupancy_pct,max_occupancy_pct,multiplier,active)
values
('Low Occupancy','occupancy',10,0,29.99,0.90,true),
('Healthy Occupancy','occupancy',20,60,74.99,1.10,true),
('High Occupancy','occupancy',30,75,84.99,1.18,true),
('Very High Occupancy','occupancy',40,85,94.99,1.28,true),
('Critical Occupancy','occupancy',50,95,100,1.40,true)
on conflict do nothing;
