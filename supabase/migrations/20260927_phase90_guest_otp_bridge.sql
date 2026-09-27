create extension if not exists pgcrypto;

-- Phase 90: Guest OTP delivery bridge (Email + SMS)
-- Delivery is provider-backed by the Next.js server route (Resend/Twilio).
-- The booking RPC trusts only a server-created, verified challenge.

create table if not exists public.anaira_guest_otp_challenges (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  channel text not null check (channel in ('email','phone')),
  destination_hash text not null,
  destination_masked text not null,
  otp_hash text not null,
  attempts integer not null default 0 check (attempts >= 0 and attempts <= 10),
  max_attempts integer not null default 5 check (max_attempts between 1 and 10),
  expires_at timestamptz not null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  last_sent_at timestamptz not null default now()
);

create index if not exists idx_anaira_guest_otp_destination
  on public.anaira_guest_otp_challenges(destination_hash, created_at desc);
create index if not exists idx_anaira_guest_otp_expiry
  on public.anaira_guest_otp_challenges(expires_at);

alter table public.anaira_guest_otp_challenges enable row level security;
revoke all on table public.anaira_guest_otp_challenges from anon, authenticated;

create or replace function public.anaira_verify_guest_otp_challenge(
  p_verification_id uuid,
  p_tenant_id uuid,
  p_channel text,
  p_destination_hash text
) returns boolean
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare v public.anaira_guest_otp_challenges;
begin
  select * into v
  from public.anaira_guest_otp_challenges
  where id=p_verification_id
    and tenant_id=p_tenant_id
    and channel=p_channel
    and destination_hash=p_destination_hash
    and verified_at is not null
    and verified_at >= now() - interval '30 minutes'
  limit 1;
  return found;
end $$;

revoke all on function public.anaira_verify_guest_otp_challenge(uuid,uuid,text,text) from public, anon, authenticated;

create or replace function public.anaira_start_verified_hotel_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,
 p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,
 p_idempotency_key text,p_source text default 'anaira-hotel-store',p_verification_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_ok boolean := false; v_channel text; v_hash text;
begin
 if p_verification_id is null then raise exception 'Customer verification is required before booking'; end if;
 if nullif(trim(coalesce(p_guest_email,'')),'') is not null then
   v_channel := 'email';
   v_hash := encode(digest(lower(trim(p_guest_email)), 'sha256'), 'hex');
   v_ok := public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash);
 end if;
 if not v_ok and nullif(trim(coalesce(p_guest_phone,'')),'') is not null then
   v_channel := 'phone';
   v_hash := encode(digest(regexp_replace(p_guest_phone,'\D','','g'), 'sha256'), 'hex');
   v_ok := public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash);
 end if;
 if not v_ok then raise exception 'The guest contact could not be verified for this booking'; end if;
 return public.anaira_start_hotel_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_coupon_code,p_addons,p_idempotency_key,p_source);
end $$;

revoke all on function public.anaira_start_verified_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from public, anon;
grant execute on function public.anaira_start_verified_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) to anon, authenticated;

-- The legacy public booking RPC is no longer callable anonymously. The verified
-- booking wrapper above is the only public customer transaction entry point.
revoke execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) from anon;
