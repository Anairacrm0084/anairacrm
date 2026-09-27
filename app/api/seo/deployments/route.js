import crypto from 'node:crypto';
import {db} from '../../../../lib/server/provider';
import {requireSeoFeature} from '../../../../lib/server/seoRuntime';

function payloadFor(action,site,body){
  if(action==='sitemap') return {type:'sitemap',siteId:site.id,domain:site.domain,content:body.content||null};
  if(action==='robots') return {type:'robots',siteId:site.id,domain:site.domain,content:body.content||null};
  if(action==='redirects') return {type:'redirects',siteId:site.id,domain:site.domain,redirects:body.redirects||[]};
  if(action==='metadata') return {type:'metadata',siteId:site.id,domain:site.domain,changes:body.changes||[]};
  if(action==='schema') return {type:'schema',siteId:site.id,domain:site.domain,schemas:body.schemas||[]};
  if(action==='content') return {type:'content',siteId:site.id,domain:site.domain,changes:body.changes||[]};
  throw new Error('Unsupported deployment action');
}
export async function GET(req){try{const siteId=new URL(req.url).searchParams.get('siteId');await requireSeoFeature(req,siteId,null,'seo-system.view');const {data,error}=await db().from('crm_seo_deployment_runs').select('*').eq('site_id',siteId).order('started_at',{ascending:false}).limit(100);if(error)throw error;const {data:targets,error:te}=await db().from('crm_seo_deployment_targets').select('*').eq('site_id',siteId);if(te)throw te;return Response.json({ok:true,runs:data||[],targets:targets||[]})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
export async function POST(req){
  const started=new Date().toISOString();let run=null;
  try{
    const body=await req.json();const {site}=await requireSeoFeature(req,body.siteId,null,'seo-system.manage');
    const targetType=body.targetType||'webhook';const action=body.action;
    const payload=payloadFor(action,site,body);
    const {data:r,error:re}=await db().from('crm_seo_deployment_runs').insert({site_id:site.id,target_type:targetType,action,status:'running',request_payload:payload,started_at:started}).select().single();if(re)throw re;run=r;
    const {data:target,error:te}=await db().from('crm_seo_deployment_targets').select('*').eq('site_id',site.id).eq('target_type',targetType).maybeSingle();if(te)throw te;
    if(!target?.endpoint) throw new Error(`Deployment target '${targetType}' is not configured`);
    const headers={'content-type':'application/json'};if(target.settings?.secret){const raw=JSON.stringify(payload);headers['x-anaira-signature']=crypto.createHmac('sha256',target.settings.secret).update(raw).digest('hex')}
    const resp=await fetch(target.endpoint,{method:'POST',headers,body:JSON.stringify(payload)});const text=await resp.text();let parsed;try{parsed=JSON.parse(text)}catch{parsed={text:text.slice(0,4000)}}
    if(!resp.ok)throw new Error(`Deployment target returned HTTP ${resp.status}`);
    await db().from('crm_seo_deployment_runs').update({status:'completed',response_payload:parsed,completed_at:new Date().toISOString()}).eq('id',run.id);
    await db().from('crm_seo_deployment_targets').update({status:'deployed',last_deployed_at:new Date().toISOString(),last_error:null,updated_at:new Date().toISOString()}).eq('id',target.id);
    return Response.json({ok:true,runId:run.id,status:'completed',response:parsed});
  }catch(e){if(run?.id)await db().from('crm_seo_deployment_runs').update({status:'failed',error_message:e.message,completed_at:new Date().toISOString()}).eq('id',run.id);return Response.json({ok:false,error:e.message,runId:run?.id||null},{status:400})}
}
