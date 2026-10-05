import { requireTenant } from '../../../../../lib/server/auth';
import { db } from '../../../../../lib/server/provider';
import {sendCrmMessage,consentPurpose} from '../../../../../lib/server/crm-communication';
export const runtime='nodejs';
export async function POST(req){
  try{
    const body=await req.json().catch(()=>({}));const tenantId=String(body.tenantId||''),queueId=String(body.queueId||'');
    const {user}=await requireTenant(req,tenantId);const s=db(req.headers.get('authorization')?.slice(7));
    const {data:q,error}=await s.from('crm_ai_action_queue').select('*').eq('tenant_id',tenantId).eq('id',queueId).maybeSingle();if(error)throw error;if(!q)throw new Error('AI action not found');if(q.status!=='approved')throw new Error('AI action must be approved before execution');
    const p=q.proposed_action||{};const type=String(q.action_type||p.type||'').toLowerCase();let result={type};
    if(type.includes('task')||type==='create_task'||p.type==='create_task'){
      const {data,error}=await s.from('crm_tasks').insert({tenant_id:tenantId,customer_id:q.customer_id||null,title:String(p.title||p.task||'AI guest follow-up'),status:'open',priority:p.priority||'normal',due_at:p.due_at||new Date(Date.now()+86400000).toISOString(),assigned_to:p.assigned_to||null}).select().single();if(error)throw error;result.task_id=data.id;
    }else if(type.includes('upsell')||p.type==='create_upsell'){
      const {data,error}=await s.from('crm_guest_upsells').insert({tenant_id:tenantId,customer_id:q.customer_id||null,stay_id:p.stay_id||null,offer_type:p.offer_type||'service',offer_name:p.offer_name||'AI Recommended Offer',amount:Number(p.amount||0),status:'offered'}).select().single();if(error)throw error;result.upsell_id=data.id;
    }else if(type.includes('cross')||p.type==='create_cross_sell'){
      const {data,error}=await s.from('crm_hotel_cross_sell_opportunities').insert({tenant_id:tenantId,customer_id:q.customer_id,stay_id:p.stay_id||null,target_product:p.target_product||'experience',offer_name:p.offer_name||'AI Recommended Experience',amount:Number(p.amount||0),status:'proposed',source:'ai',metadata:{ai_action_id:q.id}}).select().single();if(error)throw error;result.cross_sell_id=data.id;
    }else if(type==='set_vip'||type.includes('vip')){
      const {data,error}=await s.from('crm_customers').update({vip:true,updated_at:new Date().toISOString()}).eq('tenant_id',tenantId).eq('id',q.customer_id).select().single();if(error)throw error;result.customer=data.id;
    }else if(type==='create_recovery'||type.includes('recovery')){
      const {data,error}=await s.from('crm_service_recovery_cases').insert({tenant_id:tenantId,property_id:p.property_id||null,customer_id:q.customer_id,complaint_id:p.complaint_id||null,recovery_type:p.recovery_type||'service_recovery',compensation_amount:Number(p.offer_value||p.value||0),status:'open',notes:p.notes||'AI recommended recovery'}).select().single();if(error)throw error;result.recovery_id=data.id;
    }else if(type==='create_retention_task'||type.includes('retention')){
      const {data,error}=await s.from('crm_tasks').insert({tenant_id:tenantId,customer_id:q.customer_id,title:String(p.title||'AI retention follow-up'),status:'open',priority:p.priority||'high',due_at:p.due_at||new Date(Date.now()+86400000*2).toISOString()}).select().single();if(error)throw error;result.task_id=data.id;
    }else if(type==='create_reservation_followup'||type.includes('reservation_followup')){
      const {data,error}=await s.from('crm_tasks').insert({tenant_id:tenantId,customer_id:q.customer_id,title:String(p.title||'Reservation follow-up'),status:'open',priority:p.priority||'normal',due_at:p.due_at||new Date(Date.now()+86400000).toISOString(),notes:p.notes||null}).select().single();if(error)throw error;result.task_id=data.id;
    }else if(type==='send_whatsapp'||type==='send_email'||type==='send_sms'){
      const channel=type.replace('send_','');
      const {data:customer,error:ce}=await s.from('crm_customers').select('*').eq('tenant_id',tenantId).eq('id',q.customer_id).single();if(ce)throw ce;
      const {data:consent}=await s.from('crm_consents').select('status').eq('customer_id',q.customer_id).eq('channel',channel).eq('status','granted').in('purpose',['service','marketing','communications',consentPurpose(channel)]).order('captured_at',{ascending:false}).limit(1).maybeSingle();if(!consent)throw new Error(`Guest ${channel} consent is required before AI communication.`);
      const sent=await sendCrmMessage(channel,customer,String(p.message||p.body||'Anaira CRM follow-up'),p.subject);result.delivery=sent;
      await s.from('crm_interactions').insert({customer_id:q.customer_id,channel,interaction_type:'message',subject:p.subject||'AI message',notes:String(p.message||p.body||''),occurred_at:new Date().toISOString()});
    }else{
      result.status='manual_review_required';result.message='No automatic executor is registered for this AI action type.';
    }
    await s.from('crm_ai_action_queue').update({executed_at:new Date().toISOString(),result,status:result.status==='manual_review_required'?'approved':'executed'}).eq('tenant_id',tenantId).eq('id',queueId);
    await s.from('crm_audit_logs').insert({tenant_id:tenantId,actor_id:user.id,entity_type:'crm_ai_action_queue',entity_id:queueId,action:'execute',after_data:result});
    return Response.json({ok:true,result});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400});}
}
