-- Finalize public stay bookings only through the server-side endpoint.
-- That endpoint verifies the OTP challenge against the reservation's tenant and guest contact.
revoke all on function public.anaira_finalize_public_stay_booking(uuid,text,text,text,text) from public;
revoke all on function public.anaira_finalize_public_stay_booking(uuid,text,text,text,text) from anon;
revoke all on function public.anaira_finalize_public_stay_booking(uuid,text,text,text,text) from authenticated;
grant execute on function public.anaira_finalize_public_stay_booking(uuid,text,text,text,text) to service_role;
