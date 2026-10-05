import {db,open,googleToken} from './provider';
import {assertReviewPlugin} from './review-config';
import {providerAudit,auditReview} from './review-audit';
import {sendReviewRequest} from './review-delivery';

export const REVIEW_ENGINE_VERSION='v2.0.0';
export const AI_PROMPT_VERSION='v2';

const now=()=>new Date().toISOString();

function safeJson(v){
  if(v && typeof v==='object') return v;
  try{return JSON.parse(String(v||'{}'))}catch{return {}};
}

function parseAI(j){
  const text=j.output_text||'';
  try{return JSON.parse(text)}catch{}
  const m=text.match(/\{[\s\S]*\}/);if(m){try{return JSON.parse(m[0])}catch{}}
  throw new Error('AI returned invalid JSON');
}

export function normalizeAI(out){
  const sentiment=['positive','neutral','negative'].includes(out?.sentiment)?out.sentiment:'neutral';
  const score=Math.min(1,Math.max(0,Number(out?.sentiment_score??0.5)));
  const topics=Array.isArray(out?.topics)?out.topics.map(String).slice(0,20):[];
  const reply=String(out?.reply||'Thank you for your feedback.').trim().slice(0,4000);
  const escalation=Boolean(out?.escalation_required || sentiment==='negative' && score>=0.7);
  return {sentiment,sentiment_score:score,topics,reply,escalation_required:escalation};
}

export async function classifyReview({tenantId,review,settings}){
  if(settings?.ai_classification===false && settings?.ai_reply_drafts===false) return null;
  if(!process.env.OPENAI_API_KEY) throw new Error('OPENAI_API_KEY is required for AI review classification');
  const started=Date.now();
  const model=process.env.OPENAI_MODEL||'gpt-5.6-luna';
  const expiry=review.source==='google'?(review.google_content_expires_at||new Date(Date.now()+30*24*3600000).toISOString()):null;
  const input={rating:review.rating||null,author_name:review.author_name||'',review_text:review.review_text||'',business_vertical:review.business_vertical||'other',business_name:review.business_name||null,service_context:review.service_context||null};
  const schema={type:'object',additionalProperties:false,required:['sentiment','sentiment_score','topics','reply','escalation_required'],properties:{sentiment:{type:'string',enum:['positive','neutral','negative']},sentiment_score:{type:'number',minimum:0,maximum:1},topics:{type:'array',items:{type:'string'},maxItems:20},reply:{type:'string',maxLength:4000},escalation_required:{type:'boolean'}}};
  const prompt=`You are Anaira's reputation management AI for any local business or professional service. Analyze the supplied customer review. Return only the requested structured object. Never invent policies, refunds, compensation, facts, staff names, or promises. Reply should acknowledge the customer/client/patient/visitor appropriately for the supplied business context, address the review specifically when possible, stay concise, and escalate if the review indicates harm, discrimination, safety, fraud, serious service failure, or a very low rating.\nReview: ${JSON.stringify(input)}`;
  const x=await fetch('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${process.env.OPENAI_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({model,input:prompt,text:{format:{type:'json_schema',name:'anaira_review_analysis',strict:true,schema}}})});
  const j=await x.json();if(!x.ok)throw new Error(j.error?.message||'OpenAI review analysis failed');
  const out=normalizeAI(parseAI(j));
  const usage=j.usage||{};
  const s=db();
  await s.from('crm_review_ai_runs').insert({tenant_id:tenantId,review_id:review.id,model_name:model,model_version:model,prompt_version:AI_PROMPT_VERSION,input_snapshot:input,output:out,status:'completed',input_tokens:usage.input_tokens||usage.prompt_tokens||null,output_tokens:usage.output_tokens||usage.completion_tokens||null,total_tokens:usage.total_tokens||null,latency_ms:Date.now()-started,google_content_expires_at:expiry});
  return out;
}

async function getGoogleIntegration(s,tenantId){
  const {data:int,error}=await s.from('crm_seo_integrations').select('*').eq('tenant_id',tenantId).eq('provider','google_business_profile').maybeSingle();
  if(error) throw error;
  if(!int?.settings?.refresh_token) throw new Error('Google Business Profile OAuth is not connected');
  return int;
}

export async function publishGoogleReply({tenantId,review,actorId=null,automatic=false}){
  const s=db();
  const cfg=await assertReviewPlugin(tenantId);
  if(review.reply_status!=='approved' && !automatic) throw new Error('Review reply must be approved before publishing');
  if(review.source!=='google') throw new Error('Google publishing is only supported for Google reviews');
  const conn=await s.from('crm_review_google_connections').select('reply_automation_consent').eq('tenant_id',tenantId).maybeSingle();
  if(automatic){
    if(cfg.auto_publish!==true) throw new Error('Automatic reply publishing is disabled');
    if(cfg.human_approval!==false) throw new Error('Automatic reply publishing requires human_approval=false');
    if(conn.data?.reply_automation_consent!==true) throw new Error('Explicit Google reply automation consent is required');
  }
  const idem=`google:reply:${review.id}:${review.reply_text||''}`;
  const {data:prior}=await s.from('crm_review_provider_actions').select('status,response').eq('tenant_id',tenantId).eq('idempotency_key',idem).maybeSingle();
  if(prior?.status==='success') return {duplicate:true,data:prior.response};
  const int=await getGoogleIntegration(s,tenantId);
  const token=await googleToken(open(int.settings.refresh_token));
  const raw=review.raw_payload||{};
  const accountId=review.google_account_id||raw.accountId||int.settings.account_id;
  const locationId=raw.locationId||review.google_location_name?.split('/').pop();
  const name=review.google_review_name||raw.name||`accounts/${accountId}/locations/${locationId}/reviews/${review.external_review_id}`;
  const x=await fetch(`https://mybusiness.googleapis.com/v4/${name}/reply`,{method:'PUT',headers:{Authorization:`Bearer ${token}`,'content-type':'application/json'},body:JSON.stringify({comment:review.reply_text})});
  const j=await x.json();
  if(!x.ok){await providerAudit({tenantId,reviewId:review.id,provider:'google_business_profile',action:'reply',status:'failed',response:j,error:j.error?.message||'Google reply publish failed',actorId,idempotencyKey:idem,expiresAt:review.google_content_expires_at||null});throw new Error(j.error?.message||'Google reply publish failed');}
  await s.from('crm_reviews').update({reply_status:'published',status:'replied',replied_at:now(),google_review_reply_state:'PUBLISHED',google_review_reply_url:j.reviewReplyUrl||review.google_review_reply_url||null,google_update_time:j.updateTime||now(),updated_at:now()}).eq('id',review.id).eq('tenant_id',tenantId);
  await providerAudit({tenantId,reviewId:review.id,provider:'google_business_profile',action:'reply',status:'success',response:j,actorId,idempotencyKey:idem,expiresAt:review.google_content_expires_at||null});
  await auditReview({tenantId,actorId,reviewId:review.id,action:automatic?'auto_publish':'publish',before:{reply_status:review.reply_status},after:{reply_status:'published'}});
  return {duplicate:false,data:j};
}

export async function ensureRecovery({tenantId,review,ownerId=null,priority=null,dueHours=24,actorId=null}){
  const s=db();
  const {data:existing}=await s.from('crm_review_recovery_cases').select('*').eq('tenant_id',tenantId).eq('review_id',review.id).in('status',['open','in_progress']).maybeSingle();
  if(existing) return {case:existing,existing:true};
  const due=new Date(Date.now()+Number(dueHours||24)*3600000).toISOString();
  const {data:c,error}=await s.from('crm_review_recovery_cases').insert({tenant_id:tenantId,review_id:review.id,owner_id:ownerId,priority:priority||((Number(review.rating)<=2)?'critical':'high'),reason:review.review_text||'Negative review requires service recovery',due_at:due,google_content_expires_at:review.source==='google'?(review.google_content_expires_at||new Date(Date.now()+30*24*3600000).toISOString()):null}).select().single();
  if(error)throw error;
  await s.from('crm_review_sla_events').insert({tenant_id:tenantId,recovery_case_id:c.id,event_type:'opened',due_at:c.due_at,actor_id:actorId});
  await s.from('crm_review_recovery_events').insert({tenant_id:tenantId,recovery_case_id:c.id,event_type:'opened',actor_id:actorId,to_status:'open',metadata:{review_id:review.id}}).catch(()=>{});
  return {case:c,existing:false};
}

function matches(rule,ctx){
  const trigger=String(rule.trigger||'');
  if(trigger!==ctx.trigger) return false;
  const c=safeJson(rule.conditions);
  if(c.min_rating!=null && Number(ctx.review.rating||0)<Number(c.min_rating)) return false;
  if(c.max_rating!=null && Number(ctx.review.rating||0)>Number(c.max_rating)) return false;
  if(c.sentiment && c.sentiment!==ctx.sentiment) return false;
  if(c.source && c.source!==ctx.review.source) return false;
  if(c.reply_status && c.reply_status!==ctx.review.reply_status) return false;
  if(c.min_sentiment_score!=null && Number(ctx.sentimentScore||0)<Number(c.min_sentiment_score)) return false;
  if(c.topic_contains){const topics=(ctx.topics||[]).map(x=>String(x).toLowerCase());if(!topics.includes(String(c.topic_contains).toLowerCase()))return false;}
  return true;
}

async function executeAction({tenantId,rule,run,action,context,actorId=null}){
  const s=db();
  const type=String(action.type||action.name||action);
  const actionKey=`${run.id}:${type}:${context.review?.id||context.referenceId||''}`;
  const {data:existing}=await s.from('crm_review_automation_action_runs').select('id,status,result').eq('tenant_id',tenantId).eq('idempotency_key',actionKey).maybeSingle();
  if(existing?.status==='completed')return existing.result;
  const {data:ar,error:ae}=await s.from('crm_review_automation_action_runs').insert({tenant_id:tenantId,rule_id:rule.id,automation_run_id:run.id,action_type:type,idempotency_key:actionKey,status:'running'}).select().single();
  if(ae && ae.code!=='23505') throw ae;
  try{
    let result={};
    if(type==='notify'){
      const severity=action.severity||'info';
      await s.from('crm_notifications').insert({tenant_id:tenantId,notification_type:'crm_review_automation',title:action.title||rule.name,body:action.body||`Automation matched review ${context.review?.id||''}`,severity,action_url:'/ai-reviews'});
      result={notified:true};
    } else if(type==='create_recovery') {
      result=await ensureRecovery({tenantId,review:context.review,ownerId:action.ownerId||actorId,priority:action.priority,dueHours:action.dueHours||24,actorId});
    } else if(type==='ai_classify') {
      const cfg=await assertReviewPlugin(tenantId);const out=await classifyReview({tenantId,review:context.review,settings:cfg});
      if(out){await s.from('crm_reviews').update({sentiment:out.sentiment,sentiment_score:out.sentiment_score,topics:out.topics,reply_text:out.reply,status:'classified',reply_status:cfg.human_approval!==false?'pending_approval':'approved',updated_at:now()}).eq('id',context.review.id).eq('tenant_id',tenantId);} result=out||{};
    } else if(type==='publish_google') {
      result=await publishGoogleReply({tenantId,review:context.review,actorId,automatic:true});
    } else if(type==='create_followup') {
      const {data:f,error}=await s.from('crm_followup_events').insert({tenant_id:tenantId,customer_id:context.review.customer_id||null,lead_id:null,sequence_id:action.sequenceId||null,scheduled_at:new Date(Date.now()+Number(action.delayMinutes||0)*60000).toISOString(),status:'scheduled'}).select().single();
      if(error)throw error; result={followup:f};
    } else if(type==='send_review_request') {
      const customerId=context.review?.customer_id||context.customerId;if(!customerId)throw new Error('Customer is required for review request');
      const {data:source}=await s.from('crm_review_sources').select('id,review_url').eq('tenant_id',tenantId).eq('active',true).eq('source','google').limit(1).maybeSingle();
      if(!source?.review_url)throw new Error('No active Google review source URL');
      const {data:customer}=await s.from('crm_customers').select('id,full_name,phone,email').eq('id',customerId).maybeSingle();
      const channel=action.channel|| (customer?.phone?'whatsapp':customer?.email?'email':null); if(!channel)throw new Error('Customer has no supported communication channel');
      const {data:consent}=await s.from('crm_consents').select('status').eq('customer_id',customerId).eq('channel',channel).in('purpose',['marketing','review_request','communications']).eq('status','granted').order('captured_at',{ascending:false}).limit(1).maybeSingle();if(!consent)throw new Error('Communication consent not verified');
      const since=new Date(Date.now()-7*24*3600000).toISOString();const {data:recent}=await s.from('crm_review_request_jobs').select('id,status').eq('tenant_id',tenantId).eq('customer_id',customerId).eq('channel',channel).gte('created_at',since).in('status',['queued','processing','retry','sent']).limit(1).maybeSingle();if(recent){result={existingJob:recent};}else{const key=`automation:${run.id}:${customerId}:${channel}`;const {data:job,error:je}=await s.from('crm_review_request_jobs').upsert({tenant_id:tenantId,customer_id:customerId,source_id:source.id,reference_type:'automation',reference_id:context.referenceId||context.review?.id,channel,review_url:source.review_url,business_vertical:context.review?.business_vertical||source.business_vertical||'other',customer_context:{business_vertical:context.review?.business_vertical||source.business_vertical||'other'},due_at:new Date(Date.now()+Number(action.delayMinutes||0)*60000).toISOString(),next_attempt_at:new Date(Date.now()+Number(action.delayMinutes||0)*60000).toISOString(),status:'queued',attempts:0,idempotency_key:key,consent_required:true,consent_verified:true,provider:channel,message:action.message||`We'd love your feedback: ${source.review_url}`},{onConflict:'tenant_id,idempotency_key'}).select().single();if(je)throw je;if(!job)throw new Error('Failed to queue review request');result={job};}
    } else if(type==='assign_recovery') {
      if(!action.ownerId)throw new Error('ownerId required for assign_recovery');
      const c=await ensureRecovery({tenantId,review:context.review,ownerId:action.ownerId,actorId});
      const {data:updated,error}=await s.from('crm_review_recovery_cases').update({owner_id:action.ownerId,updated_at:now()}).eq('id',c.case.id).eq('tenant_id',tenantId).select().single();if(error)throw error;result={case:updated};
    } else throw new Error(`Unsupported automation action: ${type}`);
    await s.from('crm_review_automation_action_runs').update({status:'completed',result:result||{},completed_at:now()}).eq('id',ar?.id||'').eq('tenant_id',tenantId);
    return result;
  }catch(e){await s.from('crm_review_automation_action_runs').update({status:'failed',error:e.message,completed_at:now()}).eq('id',ar?.id||'').eq('tenant_id',tenantId);throw e;}
}

export async function runAutomation({tenantId,trigger,review=null,context={},actorId=null}){
  const s=db();
  const {data:rules,error}=await s.from('crm_review_automation_rules').select('*').eq('tenant_id',tenantId).eq('active',true).order('created_at',{ascending:true});if(error)throw error;
  const base={trigger,review,referenceId:context.referenceId||review?.id,customerId:context.customerId||review?.customer_id,sentiment:context.sentiment||review?.sentiment||'neutral',sentimentScore:Number(context.sentimentScore||review?.sentiment_score||0),topics:context.topics||review?.topics||[],reply_status:review?.reply_status||null};
  const executed=[];
  for(const rule of rules||[]){
    if(!matches(rule,base))continue;
    const {data:run,error:re}=await s.from('crm_review_automation_runs').insert({tenant_id:tenantId,rule_id:rule.id,reference_type:review?'review':(context.referenceType||trigger),reference_id:base.referenceId,status:'running',attempts:1,google_content_expires_at:review?.source==='google'?(review.google_content_expires_at||new Date(Date.now()+30*24*3600000).toISOString()):null}).select().single();if(re)throw re;
    try{
      const raw=safeJson(rule.actions);const list=Array.isArray(raw)?raw:(Array.isArray(raw.actions)?raw.actions:Object.entries(raw).filter(([,v])=>v===true).map(([k])=>({type:k})));
      const results=[];for(const action of list){results.push(await executeAction({tenantId,rule,run,action,context:base,actorId}));}
      await s.from('crm_review_automation_runs').update({status:'completed',completed_at:now()}).eq('id',run.id);
      executed.push({ruleId:rule.id,results});
    }catch(e){await s.from('crm_review_automation_runs').update({status:'failed',error:e.message,completed_at:now()}).eq('id',run.id);executed.push({ruleId:rule.id,error:e.message});}
  }
  return executed;
}

export async function processReview({tenantId,reviewId,actorId=null}){
  const s=db(); const settings=await assertReviewPlugin(tenantId);
  const {data:r,error}=await s.from('crm_reviews').select('*').eq('id',reviewId).eq('tenant_id',tenantId).single(); if(error||!r)throw new Error('Review not found');
  if(['classified','replied'].includes(r.status) || ['pending_approval','approved','published'].includes(r.reply_status)) return {ok:true,skipped:true,reason:'Review already processed'};
  const ai=await classifyReview({tenantId,review:r,settings}); if(!ai)return {skipped:true,reason:'AI disabled'};
  const requireApproval=settings.human_approval!==false;
  await s.from('crm_reviews').update({sentiment:ai.sentiment,sentiment_score:ai.sentiment_score,topics:ai.topics,reply_text:ai.reply,status:'classified',reply_status:requireApproval?'pending_approval':'approved',updated_at:now()}).eq('id',reviewId).eq('tenant_id',tenantId);
  await s.from('crm_review_ai_actions').insert({tenant_id:tenantId,review_id:reviewId,action_type:'reply_draft',classification:{...ai,escalation_required:ai.escalation_required},draft_reply:ai.reply,confidence:ai.sentiment_score,status:requireApproval?'pending_approval':'approved'});
  const review2={...r,...ai,reply_status:requireApproval?'pending_approval':'approved'};
  if(ai.sentiment==='negative'||Number(r.rating)<=2||ai.escalation_required){if(settings.service_recovery!==false)await ensureRecovery({tenantId,review:review2,ownerId:actorId,actorId});}
  await runAutomation({tenantId,trigger:'new_review',review:review2,context:{sentiment:ai.sentiment,sentimentScore:ai.sentiment_score,topics:ai.topics},actorId});
  await runAutomation({tenantId,trigger:ai.sentiment==='negative'||Number(r.rating)<=2?'negative_review':'review_classified',review:review2,context:{sentiment:ai.sentiment,sentimentScore:ai.sentiment_score,topics:ai.topics},actorId});
  const conn=await s.from('crm_review_google_connections').select('reply_automation_consent').eq('tenant_id',tenantId).maybeSingle();
  if(settings.auto_publish===true && !requireApproval && conn.data?.reply_automation_consent===true){await publishGoogleReply({tenantId,review:{...review2,reply_status:'approved'},automatic:true,actorId});}
  return {ok:true,ai,recoveryCandidate:ai.sentiment==='negative'||Number(r.rating)<=2,published:settings.auto_publish===true&&!requireApproval&&conn.data?.reply_automation_consent===true};
}

export async function syncGoogleSource({tenantId,sourceId=null}){
  const s=db();const settings=await assertReviewPlugin(tenantId);if(settings.google_sync===false)return {skipped:true};
  const int=await getGoogleIntegration(s,tenantId);
  let q=await s.from('crm_review_sources').select('*').eq('tenant_id',tenantId).eq('source','google').eq('active',true);
  if(q.error) throw q.error;
  let rows=q.data||[];
  if(sourceId)rows=rows.filter(x=>x.id===sourceId);
  const token=await googleToken(open(int.settings.refresh_token));let inserted=0,updated=0,total=0;
  for(const src of rows){
    const accountId=src.settings?.account_id||int.settings.account_id;const locationId=src.location_id;if(!accountId||!locationId)continue;
    let pageToken=null;
    do{const u=new URL(`https://mybusiness.googleapis.com/v4/accounts/${accountId}/locations/${locationId}/reviews`);u.searchParams.set('pageSize','50');if(pageToken)u.searchParams.set('pageToken',pageToken);const x=await fetch(u,{headers:{Authorization:`Bearer ${token}`}});const j=await x.json();if(!x.ok)throw new Error(j.error?.message||'Google review sync failed');
      for(const rv of j.reviews||[]){const ext=rv.reviewId||rv.name;if(!ext)continue;total++;const existingQ=await s.from('crm_reviews').select('id,status,reply_status,google_content_expires_at,business_vertical,business_name').eq('tenant_id',tenantId).eq('external_review_id',ext).eq('source','google').maybeSingle();const existing=existingQ.data;const expiry=existing?.google_content_expires_at || new Date(Date.now()+30*24*3600000).toISOString();const payload={tenant_id:tenantId,source:'google',business_vertical:existing?.business_vertical||src.business_vertical||'other',business_name:existing?.business_name||src.business_name||src.settings?.title||null,external_review_id:ext,google_review_name:rv.name||null,google_review_reply_url:rv.reviewReply?.reviewReplyUrl||null,google_review_reply_state:rv.reviewReply?.state||null,google_policy_violation:rv.policyViolation||null,google_review_media:rv.reviewMedia||[],google_location_name:`accounts/${accountId}/locations/${locationId}`,google_account_id:accountId,google_update_time:rv.updateTime||null,google_content_expires_at:expiry,author_name:rv.reviewer?.displayName||null,rating:({FIVE:5,FOUR:4,THREE:3,TWO:2,ONE:1})[rv.starRating]||Number(rv.starRating)||0,review_text:rv.comment||'',reviewed_at:rv.createTime||now(),language:null,status:'new',raw_payload:{...rv,locationId,accountId}};
        if(existing){
          // Never reset an already-processed review back to `new` during a provider sync.
          // Only provider-owned mutable fields are refreshed; AI/reply/recovery state is preserved.
          const {status: _incomingStatus, ...providerPayload}=payload;
          await s.from('crm_reviews').update({...providerPayload,updated_at:now()}).eq('id',existing.id).eq('tenant_id',tenantId);
          updated++;
        }else{
          await s.from('crm_reviews').insert(payload);inserted++;
        }
      }
      pageToken=j.nextPageToken||null;
    }while(pageToken);
    await s.from('crm_review_provider_sync').upsert({tenant_id:tenantId,source_id:src.id,provider:'google_business_profile',account_id:accountId,last_sync_at:now(),next_sync_at:new Date(Date.now()+3600000).toISOString(),status:'ok',last_error:null,attempts:0,settings:src.settings||{}},{onConflict:'tenant_id,source_id,provider'}).catch(()=>{});
  }
  return {total,inserted,updated};
}

export async function processQueuedWebhookEvents({limit=100}={}){
  const s=db();
  const {data:events,error}=await s.from('crm_review_webhook_events').select('*').eq('status','queued').or('next_attempt_at.is.null,next_attempt_at.lte.'+now()).order('received_at',{ascending:true}).limit(limit);
  if(error)throw error;
  let processed=0,failed=0,retried=0;
  for(const ev of events||[]){
    const attempts=Number(ev.attempts||0)+1;
    try{
      if(!ev.tenant_id){await s.from('crm_review_webhook_events').update({status:'ignored',processed_at:now(),error:'Tenant could not be mapped',attempts}).eq('id',ev.id);continue;}
      const d=safeJson(ev.payload?.decoded);const loc=d.location?.split('/').pop()||d.locationId||null;
      if(loc){
        await syncGoogleSource({tenantId:ev.tenant_id});
        const {data:newReviews}=await s.from('crm_reviews').select('id').eq('tenant_id',ev.tenant_id).eq('source','google').eq('status','new').order('reviewed_at',{ascending:false}).limit(10);
        for(const rr of newReviews||[]){ await processReview({tenantId:ev.tenant_id,reviewId:rr.id}); }
      }
      await s.from('crm_review_webhook_events').update({status:'processed',processed_at:now(),error:null,attempts,next_attempt_at:null}).eq('id',ev.id);processed++;
    }catch(e){
      const terminal=attempts>=5;
      await s.from('crm_review_webhook_events').update({status:terminal?'failed':'queued',processed_at:terminal?now():null,error:e.message,attempts,next_attempt_at:terminal?null:new Date(Date.now()+Math.min(60,2**attempts)*60000).toISOString()}).eq('id',ev.id);
      if(terminal)failed++;else retried++;
    }
  }
  return {processed,failed,retried};
}

export async function retentionCleanup(){
  const s=db();const expiry=now();const {data:rows,error}=await s.from('crm_reviews').select('id,tenant_id').eq('source','google').lt('google_content_expires_at',expiry).limit(1000);if(error)throw error;let n=0;for(const r of rows||[]){await s.from('crm_reviews').update({rating:null,review_text:'',author_name:null,sentiment:null,sentiment_score:null,topics:[],reply_text:null,raw_payload:{},google_review_media:[],google_policy_violation:null,google_review_reply_url:null,google_review_reply_state:null,updated_at:expiry}).eq('id',r.id).eq('tenant_id',r.tenant_id);n++;}
  await s.from('crm_review_ai_runs').update({input_snapshot:{},output:{}}).eq('status','completed').lt('google_content_expires_at',expiry);
  await s.from('crm_review_ai_actions').update({classification:{},draft_reply:null}).lt('google_content_expires_at',expiry);
  await s.from('crm_review_provider_actions').update({response:{},error:null}).lt('google_content_expires_at',expiry);
  await s.from('crm_review_recovery_cases').update({reason:null}).lt('google_content_expires_at',expiry);
  await s.from('crm_review_webhook_events').update({payload:{}}).lt('google_content_expires_at',expiry);
  await s.from('crm_review_automation_runs').update({status:'expired',result:{}}).lt('google_content_expires_at',expiry);
  await s.from('crm_review_automation_action_runs').update({status:'expired',result:{},error:null}).lt('google_content_expires_at',expiry);
  return {expired:n};
}
