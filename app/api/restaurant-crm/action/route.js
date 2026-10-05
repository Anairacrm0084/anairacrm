import {db} from '../../../../lib/server/provider';
import {requireTenant} from '../../../../lib/server/auth';

export const runtime='nodejs';
const now=()=>new Date().toISOString();

async function audit(s,tenantId,user,entityType,entityId,action,before=null,after=null){
  await s.from('crm_audit_logs').insert({tenant_id:tenantId,actor_id:user?.id||null,entity_type:entityType,entity_id:entityId?String(entityId):null,action,before_data:before,after_data:after}).catch(()=>{});
}

async function context(s,tenantId,propertyId,customerId=null){
  const {data:p,error:pe}=await s.from('anaira_hospitality_properties_master').select('*').eq('id',propertyId).eq('tenant_id',tenantId).eq('active',true).maybeSingle();
  if(pe) throw pe;
  if(!p) throw new Error('Property access denied');
  let customer=null;
  if(customerId){
    const {data:c,error}=await s.from('crm_customers').select('*').eq('id',customerId).eq('tenant_id',tenantId).eq('property_id',propertyId).maybeSingle();
    if(error) throw error;
    if(!c) throw new Error('Customer not found for selected property');
    customer=c;
  }
  return {p,customer};
}

export async function POST(req){
  try{
    const body=await req.json();
    const {tenantId,propertyId,action,payload={}}=body||{};
    if(!tenantId||!propertyId||!action) throw new Error('tenantId, propertyId and action are required');
    const access=await requireTenant(req,tenantId);
    const token=(req.headers.get('authorization')||'').slice(7).trim();
    const s=db(token);
    const contextCustomerId = payload.customerId || (action==='save_customer' ? payload.id : null);
    const {p,customer}=await context(s,tenantId,propertyId,contextCustomerId);

    if(action==='save_customer'){
      const id=payload.id||null;
      const data={property_id:propertyId,tenant_id:tenantId,full_name:String(payload.full_name||'').trim(),phone:payload.phone||null,email:payload.email||null,gender:payload.gender||null,date_of_birth:payload.date_of_birth||null,anniversary_date:payload.anniversary_date||null,address_line1:payload.address_line1||null,city:payload.city||null,state:payload.state||null,country:payload.country||'India',preferred_language:payload.preferred_language||'en',customer_type:payload.customer_type||'guest',vip:Boolean(payload.vip),notes:payload.notes||null,updated_at:now()};
      if(!data.full_name) throw new Error('Customer name is required');
      if(id){
        if(!customer) throw new Error('Customer not found');
        const {data:row,error}=await s.from('crm_customers').update(data).eq('id',id).eq('tenant_id',tenantId).eq('property_id',propertyId).select('*').single();
        if(error) throw error; await audit(s,tenantId,access.user,'crm_customers',id,'update',customer,row); return Response.json({ok:true,data:row});
      }
      const {data:row,error}=await s.from('crm_customers').insert({...data,created_at:now(),total_hotel_revenue:0,total_restaurant_revenue:0,total_stays:0,total_restaurant_visits:0}).select('*').single();
      if(error) throw error; await audit(s,tenantId,access.user,'crm_customers',row.id,'create',null,row); return Response.json({ok:true,data:row});
    }

    if(action==='create_complaint'){
      if(!customer) throw new Error('Select a customer');
      const {data:row,error}=await s.from('crm_complaints').insert({tenant_id:tenantId,property_id:propertyId,customer_id:customer.id,title:String(payload.title||'Restaurant complaint').trim(),description:payload.description||null,priority:payload.priority||'normal',status:'open',opened_at:now()}).select('*').single();
      if(error) throw error; await audit(s,tenantId,access.user,'crm_complaints',row.id,'create',null,row); return Response.json({ok:true,data:row});
    }

    if(action==='update_complaint'){
      if(!payload.id) throw new Error('Complaint id required');
      const {data:before,error:be}=await s.from('crm_complaints').select('*').eq('id',payload.id).eq('tenant_id',tenantId).eq('property_id',propertyId).single(); if(be) throw be;
      const next={status:payload.status||before.status,priority:payload.priority||before.priority,resolution:payload.resolution??before.resolution,updated_at:now()};
      if(next.status==='resolved' && !before.resolved_at) next.resolved_at=now();
      const {data:row,error}=await s.from('crm_complaints').update(next).eq('id',payload.id).eq('tenant_id',tenantId).eq('property_id',propertyId).select('*').single(); if(error) throw error;
      await audit(s,tenantId,access.user,'crm_complaints',row.id,'status_change',before,row); return Response.json({ok:true,data:row});
    }

    if(action==='create_feedback'){
      if(!customer) throw new Error('Select a customer');
      const rating=Number(payload.overall_rating||0); if(rating<1||rating>5) throw new Error('Overall rating must be 1-5');
      const {data:row,error}=await s.from('crm_feedback').insert({tenant_id:tenantId,property_id:propertyId,customer_id:customer.id,overall_rating:rating,room_rating:Number(payload.room_rating||0)||null,food_rating:Number(payload.food_rating||0)||null,service_rating:Number(payload.service_rating||0)||null,cleanliness_rating:Number(payload.cleanliness_rating||0)||null,comment:payload.comment||null,source:payload.source||'restaurant_crm'}).select('*').single();
      if(error) throw error;
      if(rating<3) await s.rpc('anaira_feedback_route_action',{p_tenant_id:tenantId,p_customer_id:customer.id,p_feedback_id:row.id,p_rating:rating}).catch(()=>{});
      await audit(s,tenantId,access.user,'crm_feedback',row.id,'create',null,row); return Response.json({ok:true,data:row});
    }

    if(action==='reservation_status'){
      if(!payload.id) throw new Error('Reservation id required');
      const allowed=['confirmed','seated','completed','cancelled','no_show']; if(!allowed.includes(payload.status)) throw new Error('Invalid reservation status');
      const {data:before,error:be}=await s.from('restaurant_reservations').select('*').eq('id',payload.id).eq('restaurant_id',tenantId).single(); if(be) throw be;
      const {data:row,error}=await s.from('restaurant_reservations').update({status:payload.status,updated_at:now()}).eq('id',payload.id).eq('restaurant_id',tenantId).select('*').single(); if(error) throw error;
      await s.from('anaira_reservation_workflow_events').insert({restaurant_id:tenantId,reservation_id:row.id,event_type:'status_changed',from_status:before.status,to_status:row.status,payload:{property_id:propertyId}}).catch(()=>{});
      await audit(s,tenantId,access.user,'restaurant_reservations',row.id,'status_change',before,row); return Response.json({ok:true,data:row});
    }

    if(action==='loyalty_issue'){
      if(!customer) throw new Error('Select a customer');
      const amount=Number(payload.amount); if(!Number.isFinite(amount)||amount<=0) throw new Error('Positive spend amount required');
      const {data,error}=await s.rpc('anaira_loyalty_post',{p_tenant_id:tenantId,p_customer_id:customer.id,p_domain:'crm',p_amount:amount,p_reference_type:'restaurant_crm',p_reference_id:payload.referenceId||customer.id}); if(error) throw error;
      return Response.json({ok:true,data});
    }

    if(action==='loyalty_redeem'){
      if(!customer) throw new Error('Select a customer'); if(!payload.rewardId) throw new Error('Reward is required');
      const {data,error}=await s.rpc('anaira_loyalty_redeem',{p_tenant_id:tenantId,p_customer_id:customer.id,p_reward_id:payload.rewardId,p_reference_id:payload.referenceId||customer.id}); if(error) throw error;
      return Response.json({ok:true,data});
    }

    if(action==='loyalty_reverse'){
      if(!payload.transactionId) throw new Error('Transaction id required');
      const {data:tx,error:te}=await s.from('crm_loyalty_transactions').select('*,crm_loyalty_accounts(customer_id,tenant_id)').eq('id',payload.transactionId).maybeSingle(); if(te) throw te;
      if(!tx||tx.crm_loyalty_accounts?.tenant_id!==tenantId||tx.crm_loyalty_accounts?.customer_id!==customer?.id) throw new Error('Loyalty transaction does not belong to selected customer');
      const {data,error}=await s.rpc('anaira_reverse_loyalty_transaction',{p_transaction_id:payload.transactionId,p_reason:payload.reason||'Restaurant CRM reversal'}); if(error) throw error;
      return Response.json({ok:true,data});
    }

    if(action==='create_segment'){
      const name=String(payload.name||'Restaurant Customers').trim(); if(!name) throw new Error('Segment name required');
      const definition={property_id:propertyId,tenant_id:tenantId,domain:'restaurant',filters:{min_visits:Number(payload.min_visits||0),vip_only:Boolean(payload.vip_only),high_churn_only:Boolean(payload.high_churn_only)}};
      const {data:row,error}=await s.from('crm_segments').insert({tenant_id:tenantId,property_id:propertyId,name,definition,active:true}).select('*').single(); if(error) throw error;
      return Response.json({ok:true,data:row});
    }

    if(action==='create_campaign'){
      const name=String(payload.name||'Restaurant Campaign').trim(); if(!name) throw new Error('Campaign name required');
      const {data:row,error}=await s.from('crm_campaigns').insert({tenant_id:tenantId,property_id:propertyId,name,channel:payload.channel||'whatsapp',segment_id:payload.segmentId||null,status:'draft',scheduled_at:payload.scheduled_at||null,offer_code:payload.offer_code||null}).select('*').single(); if(error) throw error;
      return Response.json({ok:true,data:row});
    }

    if(action==='execute_campaign'){
      if(!payload.id) throw new Error('Campaign id required');
      const {data:camp,error:ce}=await s.from('crm_campaigns').select('*').eq('id',payload.id).eq('tenant_id',tenantId).eq('property_id',propertyId).single(); if(ce) throw ce;
      if(camp.status!=='active') throw new Error('Campaign must be active before audience queueing');
      const definition=camp.segment_id ? (await s.from('crm_segments').select('definition').eq('id',camp.segment_id).eq('tenant_id',tenantId).eq('property_id',propertyId).maybeSingle()).data?.definition||{} : {};
      let cq=s.from('crm_customers').select('id,phone,email,vip').eq('tenant_id',tenantId).eq('property_id',propertyId).limit(5000);
      const filters=definition.filters||{};
      if(filters.vip_only===true) cq=cq.eq('vip',true);
      const {data:audience,error:ae}=await cq; if(ae) throw ae;
      let selected=audience||[];
      if(Number(filters.min_visits||0)>0){const {data:mx}=await s.from('crm_restaurant_customer_metrics').select('customer_id,total_visits').eq('tenant_id',tenantId).eq('property_id',propertyId).gte('total_visits',Number(filters.min_visits)).limit(5000);const ids=new Set((mx||[]).map(x=>x.customer_id));selected=selected.filter(x=>ids.has(x.id));}
      if(filters.high_churn_only===true){const {data:cx}=await s.from('crm_churn_scores').select('customer_id').eq('tenant_id',tenantId).eq('property_id',propertyId).eq('risk_level','high').limit(5000);const ids=new Set((cx||[]).map(x=>x.customer_id));selected=selected.filter(x=>ids.has(x.id));}
      let queued=0;
      for(const c of selected){const {error:ie}=await s.from('crm_campaign_recipients').upsert({campaign_id:camp.id,customer_id:c.id,property_id:propertyId,status:'queued'},{onConflict:'campaign_id,customer_id,property_id'});if(!ie)queued++;}
      return Response.json({ok:true,data:{campaign_id:camp.id,audience:selected.length,queued,provider_status:'NOT_CONNECTED',message:'Audience queued. No external message was sent.'}});
    }

    if(action==='campaign_status'){
      const allowed=['draft','active','paused','completed','cancelled']; if(!allowed.includes(payload.status)) throw new Error('Invalid campaign status');
      const {data:row,error}=await s.from('crm_campaigns').update({status:payload.status}).eq('id',payload.id).eq('tenant_id',tenantId).eq('property_id',propertyId).select('*').single(); if(error) throw error; return Response.json({ok:true,data:row});
    }

    if(action==='create_workflow'){
      const name=String(payload.name||'Restaurant CRM Automation').trim(); if(!name) throw new Error('Workflow name required');
      const definition={property_id:propertyId,domain:'restaurant',trigger:payload.trigger||'customer_visit',conditions:payload.conditions||{},actions:payload.actions||[{type:'create_task'}]};
      const {data:row,error}=await s.from('crm_workflows').insert({tenant_id:tenantId,name,trigger_type:payload.trigger||'customer_visit',active:true,definition}).select('*').single(); if(error) throw error; return Response.json({ok:true,data:row});
    }

    if(action==='run_workflow'){
      if(!payload.id) throw new Error('Workflow id required');
      const {data:w,error:we}=await s.from('crm_workflows').select('*').eq('id',payload.id).eq('tenant_id',tenantId).eq('property_id',propertyId).single(); if(we) throw we;
      if(!w.active) throw new Error('Workflow is inactive');
      const {data:run,error:re}=await s.from('crm_workflow_runs').insert({workflow_id:w.id,tenant_id:tenantId,status:'running',context:{property_id:propertyId,source:'restaurant_crm',payload}}).select('*').single(); if(re) throw re;
      let createdTasks=0;
      for(const a of (w.definition?.actions||[])) if(a.type==='create_task' && customer){const {error:te}=await s.from('crm_tasks').insert({tenant_id:tenantId,property_id:propertyId,customer_id:customer.id,title:a.title||'Restaurant workflow follow-up',priority:a.priority||'normal',status:'open'});if(!te)createdTasks++;}
      const {data:done,error:fe}=await s.from('crm_workflow_runs').update({status:'completed',completed_at:now()}).eq('id',run.id).select('*').single(); if(fe) throw fe;
      return Response.json({ok:true,data:{run:done,created_tasks:createdTasks}});
    }

    if(action==='create_task'){
      if(!customer) throw new Error('Select a customer');
      const {data:row,error}=await s.from('crm_tasks').insert({tenant_id:tenantId,property_id:propertyId,customer_id:customer.id,title:String(payload.title||'Restaurant CRM follow-up'),status:'open',priority:payload.priority||'normal',due_at:payload.due_at||null}).select('*').single(); if(error) throw error; return Response.json({ok:true,data:row});
    }

    if(action==='refresh_customer_intelligence'){
      if(!customer) throw new Error('Select a customer');
      const {data,error}=await s.rpc('anaira_refresh_global_customer_links',{p_tenant_id:tenantId,p_customer_id:customer.id}); if(error) throw error;
      return Response.json({ok:true,data});
    }

    throw new Error(`Unsupported Restaurant CRM action: ${action}`);
  }catch(e){ return Response.json({ok:false,error:e?.message||String(e)},{status:400}); }
}
