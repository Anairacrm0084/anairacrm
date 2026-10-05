-- Runtime pricing closure: member, personalized, corporate and negotiated context.
-- The same function is deployed to the linked Supabase project by the closure pass.
create or replace function public.anaira_start_verified_hotel_booking_transaction_v3(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,
 p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,p_idempotency_key text,p_source text default 'anaira-hotel-store',p_verification_id uuid default null,
 p_customer_id uuid default null,p_corporate_code text default null,p_negotiated_code text default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r jsonb; b public.booking_reservations%rowtype; q jsonb; m jsonb; corp record; neg record; off record; benefit record;
 base_sub numeric; discount numeric:=0; new_sub numeric; tax numeric; total numeric; tax_pct numeric:=0; cid uuid;
begin
 r:=public.anaira_start_verified_hotel_booking_transaction_v2(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_coupon_code,p_addons,p_idempotency_key,p_source,p_verification_id);
 if not coalesce((r->>'ok')::boolean,false) then return r; end if;
 select * into b from public.booking_reservations where id=(r->>'booking_id')::uuid and restaurant_id=p_tenant_id for update;
 cid:=coalesce(p_customer_id,b.customer_id); q:=coalesce(b.rate_snapshot,r->'quote'); base_sub:=coalesce((q->>'subtotal')::numeric,b.subtotal,0);
 tax_pct:=coalesce((q->>'tax_percent')::numeric,case when base_sub>0 then ((q->>'tax')::numeric/base_sub)*100 else 0 end,0);
 if cid is not null then
   select public.anaira_booking_member_context(p_tenant_id,cid,p_rate_plan_id,base_sub) into m;
   discount:=discount+greatest(0,coalesce((m->>'discount_amount')::numeric,0));
 end if;
 if nullif(trim(p_corporate_code),'') is not null then
   select * into corp from public.booking_corporate_rates x where x.restaurant_id=p_tenant_id and x.code=trim(p_corporate_code) and x.active=true
     and (x.starts_at is null or x.starts_at<=p_check_in) and (x.ends_at is null or x.ends_at>=p_check_out) limit 1;
   if corp.id is not null then
     if corp.adjustment_type='fixed' and corp.fixed_rate is not null then discount:=discount+greatest(0,base_sub-corp.fixed_rate*greatest(1,p_check_out-p_check_in));
     elsif corp.adjustment_type='percent' then discount:=discount+greatest(0,base_sub*(corp.adjustment_value/100)); end if;
   end if;
 end if;
 if nullif(trim(p_negotiated_code),'') is not null then
   select * into neg from public.booking_negotiated_rates x where x.restaurant_id=p_tenant_id and x.code=trim(p_negotiated_code) and x.active=true
     and (x.starts_at is null or x.starts_at<=p_check_in) and (x.ends_at is null or x.ends_at>=p_check_out) limit 1;
   if neg.id is not null then discount:=discount+greatest(0,base_sub-(neg.nightly_rate*greatest(1,p_check_out-p_check_in))); end if;
 end if;
 select * into off from public.booking_personalized_offers x where x.restaurant_id=p_tenant_id and x.active=true
   and (x.starts_at is null or x.starts_at<=now()) and (x.ends_at is null or x.ends_at>=now())
   and (cid is null or x.segment_code='all' or x.segment_code=coalesce(m->>'tier',m->>'segment','all')) order by x.priority asc limit 1;
 if off.id is not null then
   if coalesce(off.config->>'type','percent')='fixed' then discount:=discount+greatest(0,(off.config->>'value')::numeric);
   else discount:=discount+greatest(0,base_sub*((off.config->>'value')::numeric/100)); end if;
 end if;
 select * into benefit from public.booking_direct_benefits x where x.restaurant_id=p_tenant_id and x.active=true and x.benefit_type in ('discount','percent_discount')
   and (x.starts_at is null or x.starts_at<=now()) and (x.ends_at is null or x.ends_at>=now()) order by x.value desc limit 1;
 if benefit.id is not null then discount:=discount+greatest(0,case when benefit.benefit_type='percent_discount' then base_sub*(benefit.value/100) else benefit.value end); end if;
 discount:=least(discount,base_sub); new_sub:=greatest(0,base_sub-discount); tax:=round(new_sub*tax_pct/100,2); total:=round(new_sub+tax+coalesce((q->>'addons')::numeric,0),2);
 q:=q||jsonb_build_object('base_subtotal',base_sub,'context_discount',discount,'subtotal',new_sub,'tax',tax,'total',total,'member_context',coalesce(m,'null'::jsonb),'corporate_code',p_corporate_code,'negotiated_code',p_negotiated_code,'personalized_offer',coalesce(off.offer_code,null),'direct_benefit',coalesce(benefit.code,null));
 update public.booking_reservations set customer_id=cid,subtotal=new_sub,tax_amount=tax,total_amount=total,rate_snapshot=q,metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('runtime_pricing',true,'customer_id',cid,'corporate_code',p_corporate_code,'negotiated_code',p_negotiated_code) where id=b.id and restaurant_id=p_tenant_id;
 update public.hms_reservations set total_amount=total,balance_amount=greatest(0,total-coalesce(paid_amount,0)),rate=round(new_sub/nullif(p_check_out-p_check_in,0),2),updated_at=now() where booking_engine_reservation_id=b.id and restaurant_id=p_tenant_id;
 update public.crm_booking_transactions set amount=total,payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('quote',q,'runtime_pricing',true) where id=(r->>'transaction_id')::uuid;
 update public.anaira_payment_intents set amount=total,metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('runtime_pricing',true,'quote',q) where id=(r->>'payment_intent_id')::uuid;
 return r||jsonb_build_object('quote',q,'amount',total,'runtime_pricing',true,'discount',discount);
end $$;
revoke all on function public.anaira_start_verified_hotel_booking_transaction_v3(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid,uuid,text,text) from public;
grant execute on function public.anaira_start_verified_hotel_booking_transaction_v3(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid,uuid,text,text) to anon,authenticated;
