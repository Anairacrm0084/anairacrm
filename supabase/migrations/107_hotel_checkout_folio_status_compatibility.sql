-- Hotel checkout compatibility: allow the checkout runtime to close folios.
-- Existing checkout RPC writes status='closed'; preserve that contract while
-- keeping the existing open/settled/void states valid.
alter table public.hms_folios drop constraint if exists hms_folios_status_check;
alter table public.hms_folios add constraint hms_folios_status_check
  check (status = any (array['open'::text,'settled'::text,'void'::text,'closed'::text]));
