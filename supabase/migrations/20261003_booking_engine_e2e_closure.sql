
-- Booking Engine E2E closure: guest self-service, payment bridge, invoice snapshot,
-- abandoned recovery queue, modification execution, and booking-specific grants.

create table if not exists public.booking_recovery_jobs (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 abandoned_session_id uuid references public.booking_abandoned_sessions(id) on delete set null,
 channel text not null check (channel in ('whatsapp','email')),
 recipient text,
 template_key text not null default 'booking.abandoned.recovery',
 status text not null default 'queued' check (status in ('queued','sent','failed','skipped','cancelled')),
 attempts integer not null default 0,
 next_attempt_at timestamptz not null default now(),
 payload jsonb not null default '{}'::jsonb,
 last_error text,
 sent_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists booking_recovery_jobs_due_idx
 on public.booking_recovery_jobs(status,next_attempt_at);
alter table public.booking_recovery_jobs enable row level security;
drop policy if exists booking_recovery_jobs_tenant on public.booking_recovery_jobs;
create policy booking_recovery_jobs_tenant on public.booking_recovery_jobs
 for all to authenticated
 using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
 with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());

create or replace function public.anaira_public_booking_cancel(
 p_booking_code text,p_guest_phone text,p_reason text default 'Guest requested cancellation'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; outj jsonb;
begin
 select * into b from public.booking_reservations
 where upper(booking_code)=upper(trim(p_booking_code))
   and regexp_replace(coalesce(guest_phone,''),'\D','','g')=regexp_replace(coalesce(p_guest_phone,''),'\D','','g')
 limit 1 for update;
 if not found then raise exception 'Booking not found'; end if;
 outj:=public.anaira_cancel_hotel_booking(b.restaurant_id,b.id,p_reason,'guest-cancel:'||b.id::text||':'||to_char(clock_timestamp(),'YYYYMMDDHH24MISSMS'));
 return coalesce(outj,'{}'::jsonb)||jsonb_build_object('booking_code',b.booking_code);
end $$;
revoke all on function public.anaira_public_booking_cancel(text,text,text) from public;
grant execute on function public.anaira_public_booking_cancel(text,text,text) to anon,authenticated;

create or replace function public.anaira_public_booking_modify(
 p_booking_code text,p_guest_phone text,p_new_check_in date,p_new_check_out date,
 p_reason text default null,p_idempotency_key text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; k text; outj jsonb;
begin
 if p_new_check_in is null or p_new_check_out is null or p_new_check_out<=p_new_check_in then
   raise exception 'Valid new stay dates are required';
 end if;
 select * into b from public.booking_reservations
 where upper(booking_code)=upper(trim(p_booking_code))
   and regexp_replace(coalesce(guest_phone,''),'\D','','g')=regexp_replace(coalesce(p_guest_phone,''),'\D','','g')
 limit 1;
 if not found then raise exception 'Booking not found'; end if;
 k:=coalesce(nullif(trim(p_idempotency_key),''),'guest-modify:'||b.id::text||':'||p_new_check_in||':'||p_new_check_out);
 outj:=public.anaira_request_hotel_booking_modification(
   b.restaurant_id,b.id,p_new_check_in,p_new_check_out,b.room_type_id,b.rate_plan_id,
   greatest(1,coalesce(b.adults,2)),greatest(0,coalesce(b.children,0)),p_reason,k
 );
 return coalesce(outj,'{}'::jsonb)||jsonb_build_object('booking_code',b.booking_code);
end $$;
revoke all on function public.anaira_public_booking_modify(text,text,date,date,text,text) from public;
grant execute on function public.anaira_public_booking_modify(text,text,date,date,text,text) to anon,authenticated;

create or replace function public.anaira_public_booking_payment(
 p_booking_code text,p_guest_phone text,p_payment_method text,p_reference text default null,
 p_proof_url text default null,p_notes text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; hr public.hms_reservations%rowtype;
begin
 select * into b from public.booking_reservations
 where upper(booking_code)=upper(trim(p_booking_code))
   and regexp_replace(coalesce(guest_phone,''),'\D','','g')=regexp_replace(coalesce(p_guest_phone,''),'\D','','g')
 limit 1;
 if found then
   select * into hr from public.hms_reservations where id=b.id limit 1;
   if hr.id is not null then
     return public.anaira_submit_hotel_payment(hr.id,p_payment_method,p_reference,p_proof_url,p_notes);
   end if;
 end if;
 raise exception 'Booking not found';
end $$;
revoke all on function public.anaira_public_booking_payment(text,text,text,text,text,text) from public;
grant execute on function public.anaira_public_booking_payment(text,text,text,text,text,text) to anon,authenticated;

create or replace function public.anaira_public_booking_invoice(
 p_booking_code text,p_guest_phone text
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; s public.hms_settings%rowtype;
begin
 select * into b from public.booking_reservations
 where upper(booking_code)=upper(trim(p_booking_code))
   and regexp_replace(coalesce(guest_phone,''),'\D','','g')=regexp_replace(coalesce(p_guest_phone,''),'\D','','g')
 limit 1;
 if not found then raise exception 'Booking not found'; end if;
 select * into s from public.hms_settings where restaurant_id=b.restaurant_id limit 1;
 return jsonb_build_object(
   'ok',true,'booking_code',b.booking_code,'status',b.status,'payment_status',b.payment_status,
   'guest',jsonb_build_object('name',b.guest_name,'phone',b.guest_phone,'email',b.guest_email),
   'stay',jsonb_build_object('check_in',b.check_in,'check_out',b.check_out,'adults',b.adults,'children',b.children),
   'amounts',jsonb_build_object('subtotal',coalesce(b.subtotal,0),'tax',coalesce(b.tax_amount,0),'total',coalesce(b.total_amount,0)),
   'tax_breakdown',coalesce(b.tax_breakdown,'{}'::jsonb),'rate_snapshot',coalesce(b.rate_snapshot,'{}'::jsonb),
   'property',jsonb_build_object('name',coalesce(s.hotel_name,s.short_name,''),'city',s.city,'state',s.state,'country',s.country,'gstin',coalesce(s.metadata->>'gstin',null)),
   'issued_at',now()
 );
end $$;
revoke all on function public.anaira_public_booking_invoice(text,text) from public;
grant execute on function public.anaira_public_booking_invoice(text,text) to anon,authenticated;

-- Use the canonical premium quote for modification requests.
create or replace function public.anaira_request_hotel_booking_modification(
 p_tenant_id uuid,p_booking_id uuid,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,
 p_adults integer default 2,p_children integer default 0,p_reason text default null,p_idempotency_key text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare b public.booking_reservations%rowtype; q jsonb; req public.anaira_booking_modification_requests%rowtype; hold jsonb;
begin
 if p_idempotency_key is null then raise exception 'idempotency key is required'; end if;
 select * into req from public.anaira_booking_modification_requests where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'request_id',req.id,'status',req.status,'quote',req.quote,'payment_adjustment',req.payment_adjustment); end if;
 select * into b from public.booking_reservations where id=p_booking_id and restaurant_id=p_tenant_id for update;
 if not found then raise exception 'Booking not found'; end if;
 if b.status not in ('confirmed','payment_pending') then raise exception 'Booking cannot be modified from status %',b.status; end if;
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 q:=public.anaira_calculate_hotel_premium_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,null,'[]'::jsonb);
 hold:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,'mod:'||p_idempotency_key,p_booking_id,15);
 insert into public.anaira_booking_modification_requests(
 tenant_id,booking_id,idempotency_key,status,requested_check_in,requested_check_out,requested_room_type_id,
 requested_rate_plan_id,requested_adults,requested_children,quote,inventory_hold_id,payment_adjustment,reason,actor_id)
 values(p_tenant_id,p_booking_id,p_idempotency_key,'held',p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,
 p_adults,p_children,q,(hold->>'hold_id')::uuid,(q->>'total')::numeric-coalesce(b.total_amount,0),p_reason,auth.uid())
 returning * into req;
 update public.booking_reservations
 set metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('pending_modification_id',req.id,'pending_modification_quote',q),
     updated_at=now()
 where id=b.id;
 return jsonb_build_object('ok',true,'request_id',req.id,'status',req.status,'quote',q,'payment_adjustment',req.payment_adjustment,'inventory_hold_id',req.inventory_hold_id);
end $$;
revoke execute on function public.anaira_request_hotel_booking_modification(uuid,uuid,date,date,uuid,uuid,integer,integer,text,text) from anon;
grant execute on function public.anaira_request_hotel_booking_modification(uuid,uuid,date,date,uuid,uuid,integer,integer,text,text) to authenticated;

create or replace function public.anaira_apply_hotel_booking_modification(
 p_request_id uuid
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare req public.anaira_booking_modification_requests%rowtype; b public.booking_reservations%rowtype; old_hold uuid; old_ci date; old_co date;
begin
 select * into req from public.anaira_booking_modification_requests where id=p_request_id for update;
 if not found then raise exception 'Modification request not found'; end if;
 if req.status='applied' then return jsonb_build_object('ok',true,'status','applied','request_id',req.id); end if;
 if req.status<>'held' then raise exception 'Modification request is not ready: %',req.status; end if;
 select * into b from public.booking_reservations where id=req.booking_id for update;
 if not found then raise exception 'Booking not found'; end if;
 old_ci:=b.check_in; old_co:=b.check_out;
 select inventory_hold_id into old_hold from public.crm_booking_transactions where booking_id=b.id order by created_at desc limit 1;
 if old_hold is not null then perform public.anaira_phase13_hotel_inventory_hold_release(b.restaurant_id,old_hold,'release'); end if;
 update public.booking_reservations set
   check_in=req.requested_check_in,check_out=req.requested_check_out,room_type_id=req.requested_room_type_id,
   rate_plan_id=req.requested_rate_plan_id,adults=req.requested_adults,children=req.requested_children,
   subtotal=(req.quote->>'subtotal')::numeric,tax_amount=(req.quote->>'tax')::numeric,total_amount=(req.quote->>'total')::numeric,
   rate_snapshot=req.quote,tax_breakdown=jsonb_build_object('tax',(req.quote->>'tax')::numeric,'tax_percent',(req.quote->>'tax_percent')::numeric),
   modified_at=now(),updated_at=now(),metadata=coalesce(metadata,'{}'::jsonb)-'pending_modification_id'-'pending_modification_quote'
 where id=b.id;
 update public.anaira_booking_modification_requests set status='applied',processed_at=now(),updated_at=now() where id=req.id;
 return jsonb_build_object('ok',true,'status','applied','request_id',req.id,'booking_id',b.id,'old_check_in',old_ci,'old_check_out',old_co,'new_check_in',req.requested_check_in,'new_check_out',req.requested_check_out,'payment_adjustment',req.payment_adjustment);
end $$;
revoke all on function public.anaira_apply_hotel_booking_modification(uuid) from public;
grant execute on function public.anaira_apply_hotel_booking_modification(uuid) to authenticated;

-- Recovery queue: only create jobs for sessions that have contact data and no booking yet.
create or replace function public.anaira_queue_abandoned_booking_recovery(p_limit integer default 100)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare n integer:=0; x record; ch text; recipient text;
begin
 for x in
   select a.* from public.booking_abandoned_sessions a
   where a.recovered=false
     and a.updated_at < now()-interval '30 minutes'
     and a.updated_at > now()-interval '7 days'
     and (a.guest_email is not null or a.guest_phone is not null)
     and not exists(select 1 from public.booking_recovery_jobs j where j.abandoned_session_id=a.id and j.status in ('queued','sent'))
   order by a.updated_at asc limit greatest(1,least(coalesce(p_limit,100),500))
 loop
   if x.guest_phone is not null then ch:='whatsapp'; recipient:=x.guest_phone;
   else ch:='email'; recipient:=x.guest_email; end if;
   insert into public.booking_recovery_jobs(restaurant_id,abandoned_session_id,channel,recipient,payload)
   values(x.restaurant_id,x.id,ch,recipient,jsonb_build_object('session_id',x.session_id,'guest_name',x.guest_name,'check_in',x.check_in,'check_out',x.check_out,'quote',x.quote));
   n:=n+1;
 end loop;
 return n;
end $$;
revoke all on function public.anaira_queue_abandoned_booking_recovery(integer) from public;
grant execute on function public.anaira_queue_abandoned_booking_recovery(integer) to authenticated;

-- Tenant isolation for parity intelligence: public users should not be able to read raw competitor snapshots.
revoke all on public.booking_rate_parity_snapshots from anon,authenticated;
grant select,insert,update,delete on public.booking_rate_parity_snapshots to authenticated;

-- Public event/recovery intake stays available only through server routes; prevent direct Data API writes.
revoke insert on public.booking_conversion_events from anon,authenticated;
revoke insert,update,delete on public.booking_abandoned_sessions from anon,authenticated;


-- Ensure premium hotel bookings have an HMS reservation with the same UUID so
-- gateway/webhook/PMS flows have one canonical reservation identity.
create or replace function public.anaira_start_verified_hotel_booking_transaction_v2(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,
 p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,p_idempotency_key text,p_source text default 'anaira-hotel-store',p_verification_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_ok boolean:=false; v_channel text; v_hash text; r jsonb; q jsonb; tx public.crm_booking_transactions%rowtype;
 a jsonb; aid uuid; aq integer; unit numeric; b public.booking_reservations%rowtype; hg uuid; cid uuid; s public.hms_settings%rowtype;
begin
 if p_verification_id is null then raise exception 'Customer verification is required before booking'; end if;
 if nullif(trim(coalesce(p_guest_email,'')),'') is not null then
   v_channel:='email'; v_hash:=encode(digest(lower(trim(p_guest_email)),'sha256'),'hex');
   v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash);
 end if;
 if not v_ok and nullif(trim(coalesce(p_guest_phone,'')),'') is not null then
   v_channel:='phone'; v_hash:=encode(digest(regexp_replace(p_guest_phone,'\D','','g'),'sha256'),'hex');
   v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash);
 end if;
 if not v_ok then raise exception 'The guest contact could not be verified for this booking'; end if;
 q:=public.anaira_calculate_hotel_premium_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,p_coupon_code,p_addons);
 r:=public.anaira_start_hotel_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_coupon_code,p_addons,p_idempotency_key,p_source);
 if not coalesce((r->>'ok')::boolean,false) then return coalesce(r,'{}'::jsonb); end if;

 select * into b from public.booking_reservations where id=(r->>'booking_id')::uuid and restaurant_id=p_tenant_id for update;
 select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
 cid:=b.customer_id;
 select id into hg from public.hms_guests where restaurant_id=p_tenant_id and
   ((nullif(trim(p_guest_phone),'') is not null and phone=trim(p_guest_phone)) or
    (nullif(trim(p_guest_email),'') is not null and lower(email)=lower(trim(p_guest_email))))
   order by updated_at desc limit 1;
 if hg is null then
   insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email)
   values(p_tenant_id,cid,p_guest_name,p_guest_phone,p_guest_email) returning id into hg;
 else
   update public.hms_guests set crm_customer_id=coalesce(cid,crm_customer_id),full_name=p_guest_name,phone=p_guest_phone,email=p_guest_email,updated_at=now() where id=hg;
 end if;
 insert into public.hms_reservations(
   id,restaurant_id,reservation_code,guest_id,room_type_id,source,status,check_in,check_out,adults,children,rate,total_amount,
   notes,crm_customer_id,rate_plan_id,booking_reference,source_reference,deposit_amount,paid_amount,balance_amount,
   hospitality_type,pricing_mode,guest_count
 )
 values(
   b.id,b.restaurant_id,b.booking_code,hg,p_room_type_id,p_source,'inquiry',b.check_in,b.check_out,b.adults,b.children,
   round((q->>'subtotal')::numeric/nullif((q->>'nights')::numeric,0),2),(q->>'total')::numeric,
   'Canonical HMS mirror for Booking Engine reservation',cid,p_rate_plan_id,b.booking_code,p_idempotency_key,0,0,(q->>'total')::numeric,
   coalesce(s.hospitality_type,'hotel'),coalesce(q->>'pricing_mode','per_unit'),greatest(1,p_adults+p_children)
 )
 on conflict (id) do update set total_amount=excluded.total_amount,rate_plan_id=excluded.rate_plan_id,updated_at=now();

 update public.booking_reservations set subtotal=(q->>'subtotal')::numeric,tax_amount=(q->>'tax')::numeric,total_amount=(q->>'total')::numeric,
   rate_snapshot=q,tax_breakdown=jsonb_build_object('tax',(q->>'tax')::numeric,'tax_percent',(q->>'tax_percent')::numeric),
   metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('premium_quote',q,'hms_reservation_id',b.id)
 where id=b.id and restaurant_id=p_tenant_id;

 for a in select * from jsonb_array_elements(coalesce(p_addons,'[]'::jsonb)) loop
   aid:=nullif(a->>'id','')::uuid; aq:=greatest(1,coalesce((a->>'quantity')::integer,1));
   select price into unit from public.booking_addons where id=aid and restaurant_id=p_tenant_id and active=true;
   if unit is not null then
     insert into public.booking_reservation_addons(reservation_id,addon_id,quantity,unit_price)
     values(b.id,aid,aq,unit) on conflict do nothing;
   end if;
 end loop;

 select * into tx from public.crm_booking_transactions where id=(r->>'transaction_id')::uuid and tenant_id=p_tenant_id for update;
 if found then
   update public.crm_booking_transactions set amount=(q->>'total')::numeric,
     payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('quote',q,'premium_quote',true,'hms_reservation_id',b.id)
   where id=tx.id;
   if tx.payment_intent_id is not null then
     update public.anaira_payment_intents set amount=(q->>'total')::numeric,
       metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('premium_quote',true,'hms_reservation_id',b.id)
     where id=tx.payment_intent_id;
   end if;
 end if;
 return coalesce(r,'{}'::jsonb)||jsonb_build_object('quote',q,'amount',(q->>'total')::numeric,'hms_reservation_id',b.id);
end $$;
revoke all on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from public;
grant execute on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) to anon,authenticated;
