import {db,open,googleToken} from '../../../../lib/server/provider';
import {requireCron,requireTenant} from '../../../../lib/server/auth';
export const runtime='nodejs';
const now=()=>new Date().toISOString();

async function getSettings(s,tenantId){
  const {data:plugin}=await s.from('restaurant_plugins').select('enabled,config').eq('restaurant_id',tenantId).eq('plugin_code','ai-review-system').maybeSingle();
  if(plugin?.enabled===false)return null;
  const {data:ps}=await s.from('plugin_settings').select('config,custom_settings').eq('restaurant_id',tenantId).eq('plugin_code','ai-review-system').maybeSingle();
  return {...(plugin?.config?.settings||{}),...(ps?.config?.settings||{}),...(ps?.custom_settings||{})};
}
function parseAI(j){
  const text=j.output_text||'';try{return JSON.parse(text)}catch{}
  const m=text.match(/\{[\s\S]*\}/);if(m)try{return JSON.parse(m[0])}catch{}
  throw new Error('AI returned invalid JSON');
}
async function classify(s,tenantId,r,settings){
  if(settings.ai_classification===false&&settings.ai_reply_drafts===false)return null;
  if(!process.env.OPENAI_API_KEY)throw new Error('OPENAI_API_KEY is required for automatic AI review processing');
  const prompt=`Analyze this hospitality review. Return JSON only: {sentiment:"positive|neutral|negative",sentiment_score:number,topics:string[],reply:string,escalation_required:boolean}. Reply must be professional, specific, and never invent facts. Rating ${r.rating}/5. Review: ${r.review_text||''}`;
  const x=await fetch('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${process.env.OPENAI_API_KEY}`,'content-type':'application/json'},body:JSON.stringify({model:process.env.OPENAI_MODEL||'gpt-5-mini',input:prompt})});
  const j=await x.json();if(!x.ok)throw new Error(j.error?.message||'OpenAI review processing failed');return parseAI(j);
}
async function publishGoogle(s,tenantId,r){
  if(r.source!=='google')throw new Error('Auto-publish is currently supported for Google reviews only');
  const {data:int}=await s.from('crm_seo_integrations').select('*').eq('tenant_id',tenantId).eq('provider','google_business_profile').maybeSingle();
  if(!int?.settings?.refresh_token)throw new Error('Google Business Profile OAuth is not connected');
  const token=await googleToken(open(int.settings.refresh_token));
  const raw=r.raw_payload||{};const accountId=raw.accountId||int.settings.account_id;const locationId=raw.locationId||raw.location_id;
  const name=raw.name||`accounts/${accountId}/locations/${locationId}/reviews/${r.external_review_id}`;
  const x=await fetch(`https://mybusiness.googleapis.com/v4/${name}/reply`,{method:'PUT',headers:{Authorization:`Bearer ${token}`,'content-type':'application/json'},body:JSON.stringify({comment:r.reply_text})});const j=await x.json();if(!x.ok)throw new Error(j.error?.message||'Google reply publish failed');
  await s.from('crm_reviews').update({reply_status:'published',status:'replied',replied_at:now(),updated_at:now()}).eq('id',r.id).eq('tenant_id',tenantId);return j;
}
async function recover(s,tenantId,r){
  const {data:existing}=await s.from('crm_review_recovery_cases').select('id').eq('tenant_id',tenantId).eq('review_id',r.id).in('status',['open','in_progress']).maybeSingle();
  if(existing)return existing;
  const {data:c,error}=await s.from('crm_review_recovery_cases').insert({tenant_id:tenantId,review_id:r.id,priority:r.rating<=2?'critical':'high',reason:r.review_text,due_at:new Date(Date.now()+24*3600000).toISOString()}).select().single();if(error)throw error;
  await s.from('crm_review_sla_events').insert({tenant_id:tenantId,recovery_case_id:c.id,event_type:'opened',due_at:c.due_at});return c;
}
async function processTenant(tenantId){
  const s=db();const settings=await getSettings(s,tenantId);if(settings===null)return {tenantId,disabled:true};
  const {data:reviews,error}=await s.from('crm_reviews').select('*').eq('tenant_id',tenantId).eq('status','new').order('reviewed_at',{ascending:true}).limit(25);if(error)throw error;
  let processed=0,negative=0,published=0,recovery=0,failed=0;
  for(const r of reviews||[]){try{
    const out=await classify(s,tenantId,r,settings);if(!out)continue;
    const sentiment=['positive','neutral','negative'].includes(out.sentiment)?out.sentiment:'neutral';const topics=Array.isArray(out.topics)?out.topics:[];const reply=String(out.reply||'Thank you for your feedback.');
    const requireApproval=settings.human_approval!==false;const autoPublish=settings.auto_publish===true&&!requireApproval;
    await s.from('crm_reviews').update({sentiment,sentiment_score:Number(out.sentiment_score??.5),topics,reply_text:reply,reply_status:autoPublish?'approved':'pending_approval',status:'classified',updated_at:now()}).eq('id',r.id).eq('tenant_id',tenantId);
    await s.from('crm_review_ai_actions').insert({tenant_id:tenantId,review_id:r.id,action_type:'reply_draft',classification:{sentiment,topics,escalation_required:!!out.escalation_required},draft_reply:reply,confidence:Number(out.sentiment_score??.5),status:autoPublish?'approved':'pending_approval',created_at:now()});
    if(sentiment==='negative'||r.rating<=2||out.escalation_required){negative++;if(settings.service_recovery!==false){await recover(s,tenantId,{...r,sentiment});recovery++;}}
    if(autoPublish){await publishGoogle(s,tenantId,{...r,reply_text:reply,raw_payload:r.raw_payload});published++;}
    processed++;
  }catch(e){failed++;await s.from('crm_reviews').update({status:'processing_error',updated_at:now()}).eq('id',r.id).eq('tenant_id',tenantId);await s.from('crm_review_ai_actions').insert({tenant_id:tenantId,review_id:r.id,action_type:'processing_error',classification:{},draft_reply:null,confidence:0,status:'failed',result:{error:e.message},created_at:now()}).catch(()=>{});}}
  return {tenantId,processed,negative,recovery,published,failed};
}
export async function POST(req){try{const {tenantId}=await req.json().catch(()=>({}));if(tenantId){await requireTenant(req,tenantId);return Response.json({ok:true,...await processTenant(tenantId)});}requireCron(req);const s=db();const {data:tenants}=await s.from('crm_review_sources').select('tenant_id').eq('source','google').eq('active',true);const ids=[...new Set((tenants||[]).map(x=>x.tenant_id).filter(Boolean))];const results=[];for(const id of ids){try{results.push(await processTenant(id))}catch(e){results.push({tenantId:id,failed:true,error:e.message})}}return Response.json({ok:true,results});}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
export async function GET(req){return POST(req)}
