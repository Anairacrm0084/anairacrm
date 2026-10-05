import {db} from '../../../../lib/server/provider';
function authorize(req){const secret=process.env.CRON_SECRET;if(!secret)throw new Error('CRON_SECRET is not configured');const h=req.headers.get('authorization')||'';if(h!==`Bearer ${secret}`)throw new Error('Unauthorized cron request');}

export async function POST(req){
  try{
    authorize(req);const s=db();const tenants=new Set();
    const {data:stays,error:se}=await s.from('crm_guest_stays').select('tenant_id,customer_id,id,check_out_date').lte('check_out_date',new Date().toISOString().slice(0,10)).limit(500);if(se)throw se;
    const {data:visits,error:ve}=await s.from('crm_restaurant_visits').select('tenant_id,customer_id,id,visit_at').lte('visit_at',new Date().toISOString()).limit(500);if(ve)throw ve;
    const {data:generic,error:ge}=await s.from('crm_review_request_events').select('tenant_id,customer_id,id,reference_type,reference_id,business_vertical,completed_at,delay_hours').eq('status','eligible').lte('completed_at',new Date().toISOString()).limit(1000);if(ge)throw ge;
    const events=[
      ...(stays||[]).map(v=>({...v,reference_type:'hotel_stay',reference_id:v.id,business_vertical:'hotel',due:new Date(new Date(v.check_out_date).getTime()+24*3600000)})),
      ...(visits||[]).map(v=>({...v,reference_type:'restaurant_visit',reference_id:v.id,business_vertical:'restaurant',due:new Date(new Date(v.visit_at).getTime()+6*3600000)})),
      ...(generic||[]).map(v=>({...v,reference_type:v.reference_type||'customer_interaction',reference_id:v.reference_id||v.id,business_vertical:v.business_vertical||'other',due:new Date(new Date(v.completed_at).getTime()+Number(v.delay_hours||24)*3600000)}))
    ];
    let queued=0;
    for(const x of events){
      tenants.add(x.tenant_id);
      const {data:source}=await s.from('crm_review_sources').select('id,review_url,business_vertical,business_name').eq('tenant_id',x.tenant_id).eq('active',true).in('business_vertical',[x.business_vertical,'other']).order('created_at').limit(1).maybeSingle();
      if(!source?.review_url)continue;
      const key=`${x.reference_type}:${x.reference_id}`;
      const {data:existing}=await s.from('crm_review_request_jobs').select('id').eq('tenant_id',x.tenant_id).eq('idempotency_key',key).maybeSingle();if(existing)continue;
      const {data:customer}=await s.from('crm_customers').select('phone,email').eq('id',x.customer_id).maybeSingle();
      const channel=customer?.phone?'whatsapp':customer?.email?'email':null;if(!channel)continue;
      const {data:consent}=await s.from('crm_consents').select('status').eq('customer_id',x.customer_id).eq('channel',channel).in('purpose',['marketing','review_request','communications']).eq('status','granted').order('captured_at',{ascending:false}).limit(1).maybeSingle();
      if(!consent)continue;
      const {error}=await s.from('crm_review_request_jobs').insert({tenant_id:x.tenant_id,customer_id:x.customer_id,source_id:source.id,reference_type:x.reference_type,reference_id:x.reference_id,channel,review_url:source.review_url,business_vertical:x.business_vertical,customer_context:{reference_type:x.reference_type,business_vertical:x.business_vertical},due_at:x.due.toISOString(),next_attempt_at:x.due.toISOString(),status:'queued',attempts:0,idempotency_key:key,consent_required:true,consent_verified:true});
      if(error)throw error;queued++;
    }
    return Response.json({ok:true,queued,tenants:[...tenants]});
  }catch(e){return Response.json({ok:false,error:e.message},{status:500});}
}
export async function GET(req){return POST(req);}
