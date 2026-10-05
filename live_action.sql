create or replace function public.anaira_restaurant_crm_action(
 p_tenant_id uuid, p_property_id uuid, p_action text,
 p_customer_id uuid default null, p_payload jsonb default '{}'::jsonb
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_customer public.crm_customers%rowtype; v_id uuid; v_result jsonb:='{}'::jsonb; v_action_id uuid; v_points integer; v_offer public.crm_commercial_offers%rowtype;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 if not public.anaira_can_access_tenant(p_tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;
 if not exists(select 1 from public.anaira_hospitality_properties_master where id=p_property_id and tenant_id=p_tenant_id and active=true) then raise exception 'PROPERTY_ACCESS_DENIED'; end if;
 if p_customer_id is not null then
  select * into v_customer from public.crm_customers where id=p_customer_id and tenant_id=p_tenant_id and property_id=p_property_id;
  if v_customer.id is null then raise exception 'CUSTOMER_ACCESS_DENIED'; end if;
 end if;

 if p_action='create_task' then
  insert into public.crm_tasks(tenant_id,property_id,customer_id,title,status,priority,due_at,assigned_to)
  values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'title','Restaurant CRM follow-up'),'open',coalesce(p_payload->>'priority','normal'),nullif(p_payload->>'due_at','')::timestamptz,nullif(p_payload->>'assigned_to','')::uuid) returning id into v_id;
  v_result=jsonb_build_object('task_id',v_id);
 elsif p_action='create_complaint' then
  insert into public.crm_complaints(tenant_id,property_id,customer_id,title,description,priority,status)
  values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'title','Restaurant complaint'),p_payload->>'description',coalesce(p_payload->>'priority','normal'),'open') returning id into v_id;
  v_result=jsonb_build_object('complaint_id',v_id);
 elsif p_action='resolve_complaint' then
  v_id=nullif(p_payload->>'complaint_id','')::uuid;
  update public.crm_complaints set status='resolved',resolution=p_payload->>'resolution',resolved_at=now() where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
  if not found then raise exception 'COMPLAINT_NOT_FOUND'; end if; v_result=jsonb_build_object('complaint_id',v_id,'status','resolved');
 elsif p_action='create_food_preference' then
  insert into public.crm_food_preferences(tenant_id,property_id,customer_id,preference_type,value,frequency,confidence,last_seen_at)
  values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'preference_type','diet'),coalesce(p_payload->>'value',''),coalesce((p_payload->>'frequency')::numeric,1),coalesce((p_payload->>'confidence')::numeric,1),now())
  on conflict(customer_id,preference_type,value) do update set frequency=excluded.frequency,confidence=excluded.confidence,last_seen_at=now(); v_result=jsonb_build_object('ok',true);
 elsif p_action='create_preference' then
  insert into public.crm_customer_preferences(tenant_id,property_id,customer_id,preference_key,preference_value,source,confidence)
  values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'key','preference'),p_payload->>'value',coalesce(p_payload->>'source','manual'),coalesce((p_payload->>'confidence')::numeric,1))
  on conflict(customer_id,preference_key) do update set preference_value=excluded.preference_value,source=excluded.source,confidence=excluded.confidence; v_result=jsonb_build_object('ok',true);
 elsif p_action='create_request' then
  insert into public.crm_guest_requests(tenant_id,property_id,customer_id,request_type,description,priority,status,requested_at)
  values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'request_type','restaurant_service'),p_payload->>'description',coalesce(p_payload->>'priority','normal'),'open',now()) returning id into v_id;
  v_result=jsonb_build_object('request_id',v_id);
 elsif p_action='complete_task' then
  v_id=nullif(p_payload->>'task_id','')::uuid; update public.crm_tasks set status='completed' where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id; if not found then raise exception 'TASK_NOT_FOUND'; end if; v_result=jsonb_build_object('task_id',v_id,'status','completed');
 elsif p_action='complete_request' then
  v_id=nullif(p_payload->>'request_id','')::uuid; update public.crm_guest_requests set status='completed',completed_at=now() where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id; if not found then raise exception 'REQUEST_NOT_FOUND'; end if; v_result=jsonb_build_object('request_id',v_id,'status','completed');
 elsif p_action='escalate_request' then
  v_id=nullif(p_payload->>'request_id','')::uuid; update public.crm_guest_requests set status='escalated',escalated_at=now(),sla_status='breached' where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id; if not found then raise exception 'REQUEST_NOT_FOUND'; end if; v_result=jsonb_build_object('request_id',v_id,'status','escalated');
 elsif p_action='create_sla_event' then
  insert into public.crm_service_sla_events(tenant_id,property_id,ticket_id,event_type,due_at,actor_id,payload) values(p_tenant_id,p_property_id,nullif(p_payload->>'ticket_id','')::uuid,coalesce(p_payload->>'event_type','sla_created'),nullif(p_payload->>'due_at','')::timestamptz,auth.uid(),coalesce(p_payload,'{}'::jsonb)) returning id into v_id; v_result=jsonb_build_object('sla_event_id',v_id);
 elsif p_action='create_offer' then
  if coalesce(nullif(p_payload->>'price','')::numeric,0)<0 then raise exception 'INVALID_OFFER_PRICE'; end if;
  if nullif(p_payload->>'inventory_ref','') is not null and not exists(select 1 from public.crm_restaurant_offer_inventory where tenant_id=p_tenant_id and property_id=p_property_id and inventory_ref=p_payload->>'inventory_ref' and active=true and reserved_qty<total_qty) then raise exception 'OFFER_INVENTORY_UNAVAILABLE'; end if;
  insert into public.crm_commercial_offers(tenant_id,property_id,customer_id,source_stay_id,offer_type,title,price,currency,inventory_ref,status,expires_at,metadata)
  values(p_tenant_id,p_property_id,p_customer_id,null,coalesce(p_payload->>'offer_type','restaurant_upsell'),coalesce(p_payload->>'title','Restaurant offer'),coalesce((p_payload->>'price')::numeric,0),coalesce(p_payload->>'currency','INR'),p_payload->>'inventory_ref','proposed',nullif(p_payload->>'expires_at','')::timestamptz,coalesce(p_payload->'metadata','{}'::jsonb)) returning id into v_id;
  v_result=jsonb_build_object('offer_id',v_id,'status','proposed');
 elsif p_action='accept_offer' then
  v_id=nullif(p_payload->>'offer_id','')::uuid;
  select * into v_offer from public.crm_commercial_offers where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and customer_id=p_customer_id for update;
  if v_offer.id is null or v_offer.status<>'proposed' or (v_offer.expires_at is not null and v_offer.expires_at<=now()) then raise exception 'OFFER_NOT_AVAILABLE'; end if;
  if v_offer.inventory_ref is not null then update public.crm_restaurant_offer_inventory set reserved_qty=reserved_qty+1,updated_at=now() where tenant_id=p_tenant_id and property_id=p_property_id and inventory_ref=v_offer.inventory_ref and active=true and reserved_qty<total_qty; if not found then raise exception 'OFFER_INVENTORY_UNAVAILABLE'; end if; end if;
  update public.crm_commercial_offers set status='accepted',accepted_at=now() where id=v_id; v_result=jsonb_build_object('offer_id',v_id,'status','accepted');
 elsif p_action='record_offer_payment' then
  v_id=nullif(p_payload->>'offer_id','')::uuid;
  select * into v_offer from public.crm_commercial_offers where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and customer_id=p_customer_id for update;
  if v_offer.id is null or v_offer.status<>'accepted' then raise exception 'OFFER_NOT_PAYABLE'; end if;
  if coalesce(p_payload->>'verified','false')<>'true' or nullif(trim(p_payload->>'reference'),'') is null then raise exception 'PAYMENT_VERIFICATION_REQUIRED'; end if;
  insert into public.crm_restaurant_offer_payments(tenant_id,property_id,offer_id,provider,reference,amount,status,verified,payload,created_by,settled_at)
  values(p_tenant_id,p_property_id,v_id,coalesce(p_payload->>'provider','manual'),p_payload->>'reference',coalesce((p_payload->>'amount')::numeric,v_offer.price),'paid',true,coalesce(p_payload,'{}'::jsonb),auth.uid(),now()) returning id into v_id;
  update public.crm_commercial_offers set status='paid',paid_at=now(),revenue=v_offer.price where id=v_offer.id;
  v_result=jsonb_build_object('payment_id',v_id,'offer_id',v_offer.id,'status','paid');
 elsif p_action='pay_offer' then
  raise exception 'USE_RECORD_OFFER_PAYMENT';
 elsif p_action='fulfil_offer' then
  v_id=nullif(p_payload->>'offer_id','')::uuid;
  update public.crm_commercial_offers set status='fulfilled',fulfilled_at=now(),revenue=coalesce(revenue,price) where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and customer_id=p_customer_id and status='paid';
  if not found then raise exception 'OFFER_NOT_PAID'; end if;
  v_result=jsonb_build_object('offer_id',v_id,'status','fulfilled');
 elsif p_action='log_feedback' then
  insert into public.crm_feedback(tenant_id,property_id,customer_id,overall_rating,food_rating,service_rating,comment,source) values(p_tenant_id,p_property_id,p_customer_id,(p_payload->>'rating')::numeric,(p_payload->>'rating')::numeric,(p_payload->>'rating')::numeric,p_payload->>'comment',coalesce(p_payload->>'source','restaurant_crm')) returning id into v_id; v_result=jsonb_build_object('feedback_id',v_id);
 elsif p_action='queue_whatsapp' then
  insert into public.crm_message_log(tenant_id,property_id,customer_id,channel,direction,status,payload,created_at) values(p_tenant_id,p_property_id,p_customer_id,'whatsapp','outbound','queued',coalesce(p_payload,'{}'::jsonb),now()) returning id into v_id; v_result=jsonb_build_object('message_id',v_id,'status','queued','provider_required',true);
 elsif p_action='add_timeline' then
  v_id=public.anaira_record_crm_timeline(p_tenant_id,p_customer_id,coalesce(p_payload->>'event_type','restaurant_crm'),'restaurant_crm',coalesce(p_payload->>'source_id',gen_random_uuid()::text),coalesce(p_payload->>'title','Restaurant CRM event'),p_payload->>'description',null,coalesce(p_payload->'metadata','{}'::jsonb),now()); v_result=jsonb_build_object('timeline_id',v_id);
 elsif p_action='redeem_loyalty' then
  v_result=public.anaira_loyalty_redeem(p_tenant_id,p_customer_id,nullif(p_payload->>'reward_id','')::uuid,p_payload->>'reference_id');
 elsif p_action='earn_loyalty' then
  v_result=public.anaira_loyalty_post(p_tenant_id,p_customer_id,'restaurant',coalesce((p_payload->>'amount')::numeric,0),'restaurant_crm',p_payload->>'reference_id');
 elsif p_action='record_order_event' then
  if lower(coalesce(p_payload->>'order_source','')) not in ('marketplace','delivery','bill') then raise exception 'INVALID_ORDER_SOURCE'; end if;
  insert into public.crm_restaurant_order_events(tenant_id,property_id,customer_id,order_id,order_source,event_type,from_status,to_status,amount,payment_status,payload,idempotency_key,created_by)
  values(p_tenant_id,p_property_id,p_customer_id,nullif(p_payload->>'order_id','')::uuid,lower(p_payload->>'order_source'),coalesce(p_payload->>'event_type','status_change'),p_payload->>'from_status',p_payload->>'to_status',(p_payload->>'amount')::numeric,p_payload->>'payment_status',coalesce(p_payload,'{}'::jsonb),nullif(p_payload->>'idempotency_key',''),auth.uid()) on conflict(tenant_id,idempotency_key) do update set payload=excluded.payload returning id into v_id;
  if lower(p_payload->>'order_source')='marketplace' then update public.anaira_marketplace_orders set status=coalesce(p_payload->>'to_status',status),property_id=p_property_id,customer_id=coalesce(customer_id,p_customer_id) where id=(p_payload->>'order_id')::uuid and restaurant_id=p_tenant_id;
  elsif lower(p_payload->>'order_source')='delivery' then update public.delivery_orders set status=coalesce(p_payload->>'to_status',status),property_id=p_property_id,customer_id=coalesce(customer_id,p_customer_id) where id=(p_payload->>'order_id')::uuid and restaurant_id=p_tenant_id;
  elsif lower(p_payload->>'order_source')='bill' then update public.crm_bills set status=coalesce(p_payload->>'to_status',status),property_id=p_property_id,customer_id=coalesce(customer_id,p_customer_id) where id=(p_payload->>'order_id')::uuid and tenant_id=p_tenant_id; end if;
  v_result=jsonb_build_object('order_event_id',v_id,'status',coalesce(p_payload->>'to_status','recorded'));
 elsif p_action='record_order_payment' then
  if lower(coalesce(p_payload->>'order_source',''))='bill' then
   insert into public.crm_bill_payments(tenant_id,bill_id,provider,method,amount,reference,status,settled_at) values(p_tenant_id,(p_payload->>'order_id')::uuid,p_payload->>'provider',coalesce(p_payload->>'method','unknown'),coalesce((p_payload->>'amount')::numeric,0),p_payload->>'reference',coalesce(p_payload->>'status','pending'),case when p_payload->>'status' in ('paid','captured','settled') then now() end) returning id into v_id;
  else
   insert into public.crm_restaurant_order_events(tenant_id,property_id,customer_id,order_id,order_source,event_type,amount,payment_status,payload,created_by) values(p_tenant_id,p_property_id,p_customer_id,(p_payload->>'order_id')::uuid,lower(p_payload->>'order_source'),'payment',coalesce((p_payload->>'amount')::numeric,0),p_payload->>'status',coalesce(p_payload,'{}'::jsonb),auth.uid()) returning id into v_id;
  end if; v_result=jsonb_build_object('payment_event_id',v_id,'status',coalesce(p_payload->>'status','pending'));
 elsif p_action='prepare_campaign' then
  v_id=nullif(p_payload->>'campaign_id','')::uuid;
  if not exists(select 1 from public.crm_campaigns where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id) then raise exception 'CAMPAIGN_NOT_FOUND'; end if;
  insert into public.crm_campaign_recipients(id,campaign_id,customer_id,status,tenant_id,property_id)
  select gen_random_uuid(),v_id,c.id,'queued',p_tenant_id,p_property_id from public.crm_customers c left join public.crm_restaurant_customer_metrics m on m.customer_id=c.id and m.tenant_id=p_tenant_id and m.property_id=p_property_id where c.tenant_id=p_tenant_id and c.property_id=p_property_id and (nullif(p_payload->>'min_visits','') is null or coalesce(m.total_visits,0)>=(p_payload->>'min_visits')::int) on conflict do nothing;
  update public.crm_campaigns set status='audience_ready' where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
  insert into public.crm_restaurant_campaign_jobs(tenant_id,property_id,campaign_id) values(p_tenant_id,p_property_id,v_id); v_result=jsonb_build_object('campaign_id',v_id,'status','audience_ready');
 elsif p_action='record_campaign_event' then
  v_id=nullif(p_payload->>'recipient_id','')::uuid;
  update public.crm_campaign_recipients set status=coalesce(p_payload->>'status',status),sent_at=case when p_payload->>'status'='sent' then coalesce(sent_at,now()) else sent_at end,delivered_at=case when p_payload->>'status'='delivered' then coalesce(delivered_at,now()) else delivered_at end,opened_at=case when p_payload->>'status'='opened' then coalesce(opened_at,now()) else opened_at end,clicked_at=case when p_payload->>'status'='clicked' then coalesce(clicked_at,now()) else clicked_at end,converted_at=case when p_payload->>'status'='converted' then coalesce(converted_at,now()) else converted_at end where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id;
  if not found then raise exception 'RECIPIENT_NOT_FOUND'; end if;
  if p_payload->>'status'='converted' then insert into public.crm_campaign_attribution(tenant_id,property_id,campaign_id,customer_id,recipient_id,event_type,revenue,reference_type,reference_id) select p_tenant_id,p_property_id,campaign_id,customer_id,id,'conversion',coalesce((p_payload->>'revenue')::numeric,0),p_payload->>'reference_type',p_payload->>'reference_id' from public.crm_campaign_recipients where id=v_id on conflict do nothing; end if;
  v_result=jsonb_build_object('recipient_id',v_id,'status',p_payload->>'status');
 elsif p_action='queue_automation' then
  insert into public.crm_restaurant_automation_jobs(tenant_id,property_id,customer_id,trigger_type,action_type,payload,run_at) values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'trigger_type','manual'),coalesce(p_payload->>'action_type','add_timeline'),coalesce(p_payload,'{}'::jsonb),coalesce(nullif(p_payload->>'run_at','')::timestamptz,now())) returning id into v_id; v_result=jsonb_build_object('job_id',v_id,'status','queued');
 elsif p_action='generate_ai_insight' then
  if nullif(trim(p_payload->>'summary'),'') is null then raise exception 'AI_OUTPUT_REQUIRED'; end if;
  insert into public.crm_ai_insights(tenant_id,property_id,customer_id,insight_type,summary,recommendation,confidence,model_name,model_version,input_snapshot,status,cost,prompt_version) values(p_tenant_id,p_property_id,p_customer_id,coalesce(p_payload->>'insight_type','restaurant'),p_payload->>'summary',p_payload->>'recommendation',(p_payload->>'confidence')::numeric,p_payload->>'model_name',p_payload->>'model_version',coalesce(p_payload->'input_snapshot','{}'::jsonb),'generated',(p_payload->>'cost')::numeric,p_payload->>'prompt_version') returning id into v_id; v_result=jsonb_build_object('insight_id',v_id,'status','generated');
 elsif p_action='review_ai_insight' then
  v_id=nullif(p_payload->>'insight_id','')::uuid; update public.crm_ai_insights set status='reviewed',reviewed_by=auth.uid(),reviewed_at=now() where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and status='generated'; if not found then raise exception 'AI_INSIGHT_NOT_REVIEWABLE'; end if; v_result=jsonb_build_object('insight_id',v_id,'status','reviewed');
 elsif p_action='approve_ai_insight' then
  v_id=nullif(p_payload->>'insight_id','')::uuid; update public.crm_ai_insights set status='approved',approved_by=auth.uid(),approved_at=now() where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and status in ('reviewed','generated'); if not found then raise exception 'AI_INSIGHT_NOT_APPROVABLE'; end if; v_result=jsonb_build_object('insight_id',v_id,'status','approved');
 elsif p_action='execute_ai_insight' then
  v_id=nullif(p_payload->>'insight_id','')::uuid; if not exists(select 1 from public.crm_ai_insights where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and status='approved') then raise exception 'AI_INSIGHT_NOT_EXECUTABLE'; end if;
  insert into public.crm_restaurant_automation_jobs(tenant_id,property_id,customer_id,trigger_type,action_type,payload,run_at) select tenant_id,property_id,customer_id,'ai_approved',coalesce(p_payload->>'action_type','add_timeline'),coalesce(p_payload->'execution_payload','{}'::jsonb),now() from public.crm_ai_insights where id=v_id returning id into v_action_id;
  update public.crm_ai_insights set status='executed',executed_at=now() where id=v_id; v_result=jsonb_build_object('insight_id',v_id,'automation_job_id',v_action_id,'status','executed');
 elsif p_action='record_ai_outcome' then
  v_id=nullif(p_payload->>'insight_id','')::uuid; update public.crm_ai_insights set status='outcome',outcome=coalesce(p_payload->'outcome','{}'::jsonb) where id=v_id and tenant_id=p_tenant_id and property_id=p_property_id and status='executed'; if not found then raise exception 'AI_OUTCOME_NOT_RECORDABLE'; end if; v_result=jsonb_build_object('insight_id',v_id,'status','outcome');
 else raise exception 'UNSUPPORTED_RESTAURANT_CRM_ACTION'; end if;

 insert into public.crm_restaurant_customer_actions(tenant_id,property_id,customer_id,action_type,status,payload,result,created_by,completed_at) values(p_tenant_id,p_property_id,p_customer_id,p_action,'completed',coalesce(p_payload,'{}'::jsonb),coalesce(v_result,'{}'::jsonb),auth.uid(),now()) returning id into v_action_id;
 if p_customer_id is not null then perform public.anaira_record_crm_timeline(p_tenant_id,p_customer_id,'restaurant_crm.'||p_action,'restaurant_crm',v_action_id::text,initcap(replace(p_action,'_',' ')),null,null,coalesce(v_result,'{}'::jsonb),now()); end if;
 perform public.anaira_crm_record_action(p_tenant_id,p_property_id,'restaurant_crm',v_action_id,p_action,coalesce(v_result,'{}'::jsonb));
 return jsonb_build_object('ok',true,'action_id',v_action_id,'result',v_result);
exception when others then
 if p_tenant_id is not null and public.anaira_can_access_tenant(p_tenant_id) and p_property_id is not null then
  insert into public.crm_restaurant_customer_actions(tenant_id,property_id,customer_id,action_type,status,payload,result,created_by) values(p_tenant_id,p_property_id,p_customer_id,p_action,'failed',coalesce(p_payload,'{}'::jsonb),jsonb_build_object('error',sqlerrm),auth.uid());
 end if; raise;
end $$;
revoke all on function public.anaira_restaurant_crm_action(uuid,uuid,text,uuid,jsonb) from public,anon; grant execute on function public.anaira_restaurant_crm_action(uuid,uuid,text,uuid,jsonb) to authenticated;

revoke all on function public.anaira_restaurant_crm_action(uuid,uuid,text,uuid,jsonb) from public,anon; grant execute on function public.anaira_restaurant_crm_action(uuid,uuid,text,uuid,jsonb) to authenticated;