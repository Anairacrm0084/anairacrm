-- Canonical GST invoice numbering, invoice snapshots and credit notes.
create table if not exists public.booking_invoice_sequences(
 restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
 prefix text not null default 'INV', fiscal_year text not null default '', next_number bigint not null default 1,
 updated_at timestamptz not null default now());
create table if not exists public.booking_invoice_snapshots(
 id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 booking_id uuid not null,invoice_number text not null unique,invoice_type text not null default 'tax_invoice',
 billing_name text,billing_email text,billing_phone text,billing_address text,billing_gstin text,billing_state text,
 property_name text,property_address text,property_gstin text,property_state text,
 cgst_amount numeric(14,2) not null default 0,sgst_amount numeric(14,2) not null default 0,igst_amount numeric(14,2) not null default 0,
 taxable_amount numeric(14,2) not null default 0,total_amount numeric(14,2) not null default 0,lines jsonb not null default '[]',
 status text not null default 'issued',issued_at timestamptz not null default now(),metadata jsonb not null default '{}');
create table if not exists public.booking_credit_notes(
 id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 booking_id uuid,invoice_number text,credit_note_number text not null unique,reason text,subtotal numeric(14,2) not null default 0,
 cgst_amount numeric(14,2) not null default 0,sgst_amount numeric(14,2) not null default 0,igst_amount numeric(14,2) not null default 0,
 total_amount numeric(14,2) not null default 0,status text not null default 'issued',issued_at timestamptz not null default now(),metadata jsonb not null default '{}');
alter table public.booking_invoice_snapshots enable row level security; alter table public.booking_credit_notes enable row level security;
drop policy if exists booking_invoice_snapshots_tenant on public.booking_invoice_snapshots;
drop policy if exists booking_credit_notes_tenant on public.booking_credit_notes;
create policy booking_invoice_snapshots_tenant on public.booking_invoice_snapshots for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_credit_notes_tenant on public.booking_credit_notes for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create or replace function public.anaira_issue_booking_invoice(p_booking_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare b public.booking_reservations%rowtype;s public.hms_settings%rowtype;inv public.booking_invoice_snapshots%rowtype;tax numeric:=coalesce(b.tax_amount,0);taxable numeric:=greatest(0,coalesce(b.total_amount,0)-tax);cgst numeric:=0;sgst numeric:=0;igst numeric:=0;state_same boolean;fy text;seq bigint;num text;
begin
 select * into b from public.booking_reservations where id=p_booking_id for update;if not found then raise exception 'Booking not found';end if;
 select * into s from public.hms_settings where restaurant_id=b.restaurant_id limit 1;
 fy:=to_char(current_date,'YYYY')||'-'||to_char(current_date+interval '1 year','YY');
 insert into public.booking_invoice_sequences(restaurant_id,fiscal_year,next_number) values(b.restaurant_id,fy,2)
 on conflict(restaurant_id) do update set fiscal_year=excluded.fiscal_year,next_number=case when booking_invoice_sequences.fiscal_year=excluded.fiscal_year then booking_invoice_sequences.next_number+1 else 2 end,updated_at=now()
 returning next_number-1 into seq;
 num:=coalesce((select prefix from public.booking_invoice_sequences where restaurant_id=b.restaurant_id),'INV')||'/'||replace(fy,'-','/')||'/'||lpad(seq::text,5,'0');
 state_same:=lower(coalesce(s.state,''))<>'' and lower(coalesce(s.state,''))=lower(coalesce(b.metadata->'billing'->>'state',''));
 if tax>0 then if state_same then cgst:=round(tax/2,2);sgst:=tax-cgst;else igst:=tax;end if;end if;
 insert into public.booking_invoice_snapshots(restaurant_id,booking_id,invoice_number,billing_name,billing_email,billing_phone,billing_address,billing_gstin,billing_state,property_name,property_address,property_gstin,property_state,cgst_amount,sgst_amount,igst_amount,taxable_amount,total_amount,lines)
 values(b.restaurant_id,b.id,num,b.guest_name,b.guest_email,b.guest_phone,b.metadata->'billing'->>'address',b.metadata->'billing'->>'gstin',b.metadata->'billing'->>'state',coalesce(s.hotel_name,s.short_name,''),concat_ws(', ',s.address,s.city,s.state,s.country),s.metadata->>'gstin',s.state,cgst,sgst,igst,taxable,b.total_amount,jsonb_build_array(jsonb_build_object('description','Accommodation','amount',b.subtotal),jsonb_build_object('description','Tax','amount',tax))) on conflict(invoice_number) do update set total_amount=excluded.total_amount;
 select * into inv from public.booking_invoice_snapshots where invoice_number=num;return jsonb_build_object('ok',true,'invoice',to_jsonb(inv));
end $fn$;
grant execute on function public.anaira_issue_booking_invoice(uuid) to authenticated;
create or replace function public.anaira_issue_booking_credit_note(p_booking_id uuid,p_reason text default 'Booking cancellation/refund')
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare b public.booking_reservations%rowtype;inv public.booking_invoice_snapshots%rowtype;cn public.booking_credit_notes%rowtype;n bigint;
begin
 select * into b from public.booking_reservations where id=p_booking_id for update;if not found then raise exception 'Booking not found';end if;
 select * into inv from public.booking_invoice_snapshots where booking_id=b.id order by issued_at desc limit 1;if inv.id is null then perform public.anaira_issue_booking_invoice(b.id);select * into inv from public.booking_invoice_snapshots where booking_id=b.id order by issued_at desc limit 1;end if;
 select count(*)+1 into n from public.booking_credit_notes where restaurant_id=b.restaurant_id and issued_at::date=current_date;
 insert into public.booking_credit_notes(restaurant_id,booking_id,invoice_number,credit_note_number,reason,subtotal,cgst_amount,sgst_amount,igst_amount,total_amount) values(b.restaurant_id,b.id,inv.invoice_number,'CN/'||to_char(current_date,'YYYYMMDD')||'/'||lpad(n::text,4,'0'),p_reason,inv.taxable_amount,inv.cgst_amount,inv.sgst_amount,inv.igst_amount,inv.total_amount) returning * into cn;
 return jsonb_build_object('ok',true,'credit_note',to_jsonb(cn));
end $fn$;
grant execute on function public.anaira_issue_booking_credit_note(uuid,text) to authenticated;
