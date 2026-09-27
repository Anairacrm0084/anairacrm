-- Phase 87: Hotel Marketplace QR sharing + verified customer booking gate.
-- QR opens the business-owned /book/:restaurant_id store.
-- Booking transaction is allowed only for an authenticated customer whose
-- phone or email is confirmed and matches the contact entered on the booking.

create or replace function public.anaira_start_verified_hotel_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,
 p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,
 p_idempotency_key text,p_source text default 'anaira-hotel-store'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare u_email text; u_phone text; email_verified timestamptz; phone_verified timestamptz;
begin
 if auth.uid() is null then raise exception 'Customer verification is required before booking'; end if;
 select email,phone,email_confirmed_at,phone_confirmed_at into u_email,u_phone,email_verified,phone_verified from auth.users where id=auth.uid();
 if email_verified is null and phone_verified is null then raise exception 'Please verify your phone number or email address before booking'; end if;
 if email_verified is not null and nullif(trim(p_guest_email),'') is not null and lower(trim(p_guest_email))=lower(coalesce(u_email,'')) then
   return public.anaira_start_hotel_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_coupon_code,p_addons,p_idempotency_key,p_source);
 elsif phone_verified is not null and nullif(trim(p_guest_phone),'') is not null and regexp_replace(p_guest_phone,'\D','','g')=regexp_replace(coalesce(u_phone,''),'\D','','g') then
   return public.anaira_start_hotel_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_coupon_code,p_addons,p_idempotency_key,p_source);
 else
   raise exception 'The verified email/phone does not match the guest contact entered for this booking';
 end if;
end $$;

revoke all on function public.anaira_start_verified_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) from public;
grant execute on function public.anaira_start_verified_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) to authenticated;

alter table public.anaira_store_memberships add column if not exists marketplace_qr_enabled boolean not null default true;
alter table public.anaira_store_memberships add column if not exists marketplace_booking_verification text not null default 'email_or_phone';
