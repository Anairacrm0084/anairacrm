-- Anaira Booking Engine runtime patch applied to live Supabase 2026-10-03.
-- This migration documents the production closure layer added after the premium closure.
-- Provider secrets are intentionally not stored here.

create table if not exists public.booking_invoices (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 booking_id uuid not null references public.booking_reservations(id) on delete cascade, invoice_number text not null,
 invoice_type text not null default 'tax_invoice', status text not null default 'issued', legal_name text, gstin text,
 place_of_supply text, guest_name text, guest_email text, guest_phone text, currency text not null default 'INR',
 taxable_amount numeric(14,2) not null default 0, cgst_amount numeric(14,2) not null default 0, sgst_amount numeric(14,2) not null default 0,
 igst_amount numeric(14,2) not null default 0, tax_amount numeric(14,2) not null default 0, total_amount numeric(14,2) not null default 0,
 payload jsonb not null default '{}'::jsonb, issued_at timestamptz not null default now(), created_at timestamptz not null default now(),
 unique(restaurant_id,invoice_number)
);
create index if not exists booking_invoices_booking_idx on public.booking_invoices(booking_id,issued_at desc);
create table if not exists public.booking_credit_notes (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 booking_id uuid not null references public.booking_reservations(id) on delete cascade, invoice_id uuid references public.booking_invoices(id) on delete set null,
 credit_note_number text not null, amount numeric(14,2) not null default 0, reason text, status text not null default 'issued',
 payload jsonb not null default '{}'::jsonb, issued_at timestamptz not null default now(), unique(restaurant_id,credit_note_number)
);
create table if not exists public.booking_payment_reconciliation (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 payment_intent_id uuid not null references public.anaira_payment_intents(id) on delete cascade,
 booking_id uuid references public.booking_reservations(id) on delete set null, provider text, provider_payment_id text,
 expected_amount numeric(14,2) not null default 0, settled_amount numeric(14,2) not null default 0, variance numeric(14,2) not null default 0,
 status text not null default 'pending', last_event_id text, details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(payment_intent_id)
);
alter table public.booking_invoices enable row level security;
alter table public.booking_credit_notes enable row level security;
alter table public.booking_payment_reconciliation enable row level security;
revoke all on public.booking_invoices,public.booking_credit_notes,public.booking_payment_reconciliation from anon;
grant select on public.booking_invoices,public.booking_credit_notes to authenticated;
drop policy if exists booking_invoices_tenant_select on public.booking_invoices;
drop policy if exists booking_credit_notes_tenant_select on public.booking_credit_notes;
drop policy if exists booking_payment_recon_tenant_select on public.booking_payment_reconciliation;
create policy booking_invoices_tenant_select on public.booking_invoices for select to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_credit_notes_tenant_select on public.booking_credit_notes for select to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_payment_recon_tenant_select on public.booking_payment_reconciliation for select to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

-- Public guest self-service functions validate booking code + normalized guest phone.
create or replace function public.anaira_public_booking_update_preferences(p_booking_code text,p_guest_phone text,p_preferences jsonb)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare b public.booking_reservations%rowtype;
begin
 select * into b from public.booking_reservations where upper(booking_code)=upper(trim(p_booking_code))
 and regexp_replace(coalesce(guest_phone,''),'\D','','g')=regexp_replace(coalesce(p_guest_phone,''),'\D','','g') limit 1 for update;
 if not found then raise exception 'Booking not found'; end if;
 update public.booking_reservations set guest_preferences=coalesce(p_preferences,'{}'::jsonb),special_requests=coalesce(nullif(trim(p_preferences->>'special_requests'),''),special_requests),updated_at=now() where id=b.id;
 update public.hms_reservations set special_requests=coalesce(p_preferences,'{}'::jsonb),updated_at=now() where id=b.id;
 return jsonb_build_object('ok',true,'booking_code',b.booking_code,'guest_preferences',coalesce(p_preferences,'{}'::jsonb));
end
$fn$;
grant execute on function public.anaira_public_booking_update_preferences(text,text,jsonb) to anon,authenticated;

-- Payment reconciliation records expected vs provider-settled state.
create or replace function public.anaira_reconcile_booking_payment(p_payment_intent_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare p public.anaira_payment_intents%rowtype; b public.booking_reservations%rowtype; settled numeric:=0; variance numeric; st text;
begin
 select * into p from public.anaira_payment_intents where id=p_payment_intent_id for update; if not found then raise exception 'Payment intent not found'; end if;
 select * into b from public.booking_reservations where id=p.reference_id and p.reference_type='hotel_booking';
 select case when p.status in ('paid','authorized') then p.amount else 0 end into settled;
 variance:=round(settled-coalesce(p.amount,0),2); st:=case when abs(variance)<0.01 then 'matched' else 'mismatch' end;
 insert into public.booking_payment_reconciliation(restaurant_id,payment_intent_id,booking_id,provider,provider_payment_id,expected_amount,settled_amount,variance,status,details)
 values(p.restaurant_id,p.id,b.id,p.provider,p.provider_payment_id,p.amount,settled,variance,st,jsonb_build_object('payment_status',p.status))
 on conflict(payment_intent_id) do update set settled_amount=excluded.settled_amount,variance=excluded.variance,status=excluded.status,provider_payment_id=excluded.provider_payment_id,details=excluded.details,updated_at=now();
 return jsonb_build_object('ok',true,'status',st,'expected_amount',p.amount,'settled_amount',settled,'variance',variance);
end
$fn$;
grant execute on function public.anaira_reconcile_booking_payment(uuid) to authenticated,service_role;

-- Do not expose internal payment state transition or canonical booking transaction directly through anon RPC.
revoke execute on function public.anaira_mark_payment_verified(uuid,text,text,text,text,jsonb) from anon;
revoke execute on function public.anaira_reconcile_booking_payment(uuid) from anon;
