alter table public.booking_engine_settings add column if not exists payment_config jsonb not null default '{}'::jsonb;

create table if not exists public.anaira_hotel_payment_submissions (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 reservation_id uuid not null,
 payment_intent_id uuid,
 transaction_id uuid,
 method text not null check (method in ('pay_at_hotel','bank_transfer','qr_scan')),
 receipt_path text,
 note text,
 status text not null default 'submitted' check (status in ('submitted','verified','rejected')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists anaira_hotel_payment_submissions_tenant_idx on public.anaira_hotel_payment_submissions(tenant_id,created_at desc);
create index if not exists anaira_hotel_payment_submissions_res_idx on public.anaira_hotel_payment_submissions(reservation_id);
alter table public.anaira_hotel_payment_submissions enable row level security;
drop policy if exists anaira_hotel_payment_submissions_select on public.anaira_hotel_payment_submissions;
create policy anaira_hotel_payment_submissions_select on public.anaira_hotel_payment_submissions for select to authenticated using (tenant_id in (select p.restaurant_id from public.profiles p where p.id=auth.uid()));

create or replace function public.anaira_start_hms_hotel_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,
 p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_idempotency_key text,p_source text default 'anaira-hotel-store'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare rt public.hms_room_types%rowtype; rp public.hms_rate_plans%rowtype; s public.hms_settings%rowtype;
 tx public.crm_booking_transactions%rowtype; hg uuid; cid uuid; bid uuid; code text; h jsonb; pi public.anaira_payment_intents%rowtype;
 d date; nights int; nightly numeric; room_total numeric:=0; extra_total numeric:=0; tax numeric:=0; total numeric:=0; tax_pct numeric:=0;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 nights:=p_check_out-p_check_in;
 select * into rt from public.hms_room_types where id=p_room_type_id and restaurant_id=p_tenant_id and active=true;
 if not found then raise exception 'Room type not found'; end if;
 if p_adults<1 or p_children<0 or p_adults>rt.max_adults or p_children>rt.max_children then raise exception 'Guest occupancy exceeds room capacity'; end if;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_tenant_id and room_type_id=p_room_type_id and active=true
   and (active_from is null or active_from<=p_check_in) and (active_to is null or active_to>=p_check_out-1);
 if not found then raise exception 'Selected rate plan is not active for these dates'; end if;
 if nights<coalesce(rp.min_stay,1) then raise exception 'Minimum stay for this rate plan is % night(s)',rp.min_stay; end if;
 if rp.max_stay is not null and nights>rp.max_stay then raise exception 'Maximum stay for this rate plan is % night(s)',rp.max_stay; end if;
 select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
 tax_pct:=coalesce(rt.tax_percent,s.default_tax_percent,s.tax_percent,0);
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
   nightly:=case when extract(isodow from d) in (6,7) and coalesce(rp.weekend_rate,0)>0 then rp.weekend_rate else rp.rate end;
   nightly:=nightly*coalesce(nullif(rp.seasonal_multiplier,0),1);
   room_total:=room_total+nightly;
 end loop;
 extra_total:=greatest(0,p_adults-rt.max_adults)*coalesce(rp.extra_adult,0)*nights + greatest(0,p_children-rt.max_children)*coalesce(rp.extra_child,0)*nights;
 total:=round(room_total+extra_total,2); tax:=round(total*tax_pct/100,2); total:=round(total+tax,2);
 select * into tx from public.crm_booking_transactions where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key for update;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction_id',tx.id,'booking_id',tx.booking_id,'payment_intent_id',tx.payment_intent_id,'amount',tx.amount,'state',tx.state,'quote',tx.payload->'quote'); end if;
 cid:=public.anaira_resolve_crm_customer(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email);
 select id into hg from public.hms_guests where restaurant_id=p_tenant_id and ((nullif(trim(p_guest_phone),'') is not null and phone=trim(p_guest_phone)) or (nullif(trim(p_guest_email),'') is not null and lower(email)=lower(trim(p_guest_email)))) order by updated_at desc limit 1;
 if hg is null then insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email) values(p_tenant_id,cid,p_guest_name,p_guest_phone,p_guest_email) returning id into hg;
 else update public.hms_guests set crm_customer_id=coalesce(cid,crm_customer_id),full_name=p_guest_name,phone=p_guest_phone,email=p_guest_email,updated_at=now() where id=hg; end if;
 bid:=gen_random_uuid(); code:='ANH-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into public.hms_reservations(id,restaurant_id,reservation_code,guest_id,room_type_id,source,status,check_in,check_out,adults,children,rate,total_amount,notes,crm_customer_id,rate_plan_id,booking_reference,source_reference,deposit_amount,paid_amount,balance_amount)
 values(bid,p_tenant_id,code,hg,p_room_type_id,p_source,'inquiry',p_check_in,p_check_out,p_adults,p_children,round(room_total/nights,2),total,'Created by Anaira HMS booking engine',cid,p_rate_plan_id,code,p_idempotency_key,0,0,total);
 h:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,p_idempotency_key,bid,15);
 insert into public.crm_booking_transactions(tenant_id,booking_id,customer_id,inventory_hold_id,state,idempotency_key,payload,amount,expires_at)
 values(p_tenant_id,bid,cid,(h->>'hold_id')::uuid,'payment_pending',p_idempotency_key,jsonb_build_object('quote',jsonb_build_object('nights',nights,'room_rate',round(room_total/nights,2),'subtotal',round(room_total+extra_total,2),'tax',tax,'total',total),'hms_reservation_id',bid,'source',p_source),total,(h->>'expires_at')::timestamptz) returning * into tx;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,currency,status,idempotency_key,metadata)
 values(p_tenant_id,'hotel_booking',bid,'manual',total,coalesce(s.currency,'INR'),'created','hotel:'||p_idempotency_key,jsonb_build_object('booking_transaction_id',tx.id,'hms_reservation_id',bid,'booking_code',code,'hold_id',h->>'hold_id','rate_plan_id',p_rate_plan_id)) returning * into pi;
 update public.crm_booking_transactions set payment_intent_id=pi.id where id=tx.id;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'booking_id',bid,'hms_reservation_id',bid,'booking_code',code,'payment_intent_id',pi.id,'hold_id',h->>'hold_id','amount',total,'quote',jsonb_build_object('nights',nights,'room_rate',round(room_total/nights,2),'subtotal',round(room_total+extra_total,2),'tax',tax,'total',total),'rate_plan',jsonb_build_object('id',rp.id,'name',rp.name,'code',rp.code,'board_type',rp.board_type,'refundable',rp.refundable,'deposit_percent',rp.deposit_percent),'state','payment_pending');
end $$;
revoke all on function public.anaira_start_hms_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) from public;
grant execute on function public.anaira_start_hms_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) to anon,authenticated;

create or replace function public.anaira_finalize_hotel_booking_payment(
 p_transaction_id uuid,p_method text,p_receipt_path text default null,p_note text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare tx public.crm_booking_transactions%rowtype; r public.hms_reservations%rowtype; pi public.anaira_payment_intents%rowtype; h public.anaira_hotel_inventory_holds%rowtype; s public.hms_settings%rowtype; sub uuid;
begin
 if p_method not in ('pay_at_hotel','bank_transfer','qr_scan') then raise exception 'Invalid payment method'; end if;
 if p_method in ('bank_transfer','qr_scan') and nullif(trim(coalesce(p_receipt_path,'')),'') is null then raise exception 'Payment receipt is required'; end if;
 select * into tx from public.crm_booking_transactions where id=p_transaction_id for update;
 if not found then raise exception 'Booking transaction not found'; end if;
 select * into r from public.hms_reservations where id=tx.booking_id for update;
 select * into pi from public.anaira_payment_intents where id=tx.payment_intent_id for update;
 select * into h from public.anaira_hotel_inventory_holds where id=tx.inventory_hold_id for update;
 if h.status='held' and h.expires_at<now() then raise exception 'Booking hold expired. Please check availability again.'; end if;
 if r.status in ('confirmed','checked_in','checked_out') then return jsonb_build_object('ok',true,'already_confirmed',true,'booking_id',r.id,'booking_code',r.reservation_code,'status',r.status); end if;
 update public.hms_reservations set status='confirmed',notes=coalesce(notes,'')||' | Payment method: '||p_method,updated_at=now() where id=r.id;
 perform public.anaira_phase13_hotel_inventory_hold_release(r.restaurant_id,h.id,'consume');
 update public.anaira_payment_intents set status=case when p_method='pay_at_hotel' then 'pending' else 'proof_submitted' end,metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('payment_method',p_method,'receipt_path',p_receipt_path),updated_at=now() where id=pi.id;
 update public.crm_booking_transactions set state=case when p_method='pay_at_hotel' then 'confirmed' else 'payment_proof_submitted' end,payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('payment_method',p_method,'receipt_path',p_receipt_path),updated_at=now() where id=tx.id;
 insert into public.anaira_hotel_payment_submissions(tenant_id,reservation_id,payment_intent_id,transaction_id,method,receipt_path,note,status) values(r.restaurant_id,r.id,pi.id,tx.id,p_method,p_receipt_path,p_note,'submitted') returning id into sub;
 return jsonb_build_object('ok',true,'booking_id',r.id,'booking_code',r.reservation_code,'status','confirmed','payment_method',p_method,'payment_submission_id',sub,'payment_status',case when p_method='pay_at_hotel' then 'pending' else 'proof_submitted' end);
end $$;
revoke all on function public.anaira_finalize_hotel_booking_payment(uuid,text,text,text) from public;
grant execute on function public.anaira_finalize_hotel_booking_payment(uuid,text,text,text) to anon,authenticated;

insert into storage.buckets(id,name,public) values('hotel-booking-receipts','hotel-booking-receipts',false) on conflict (id) do nothing;

drop policy if exists hotel_booking_receipts_anon_insert on storage.objects;
create policy hotel_booking_receipts_anon_insert on storage.objects for insert to anon,authenticated with check (bucket_id='hotel-booking-receipts');
drop policy if exists hotel_booking_receipts_auth_read on storage.objects;
create policy hotel_booking_receipts_auth_read on storage.objects for select to authenticated using (bucket_id='hotel-booking-receipts');
