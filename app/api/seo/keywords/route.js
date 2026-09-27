
import {db} from '../../../../lib/server/provider';import {requireSeoFeature} from '../../../../lib/server/seoRuntime';
export const runtime='nodejs';
const auth=()=>Buffer.from(`${process.env.DATAFORSEO_LOGIN}:${process.env.DATAFORSEO_PASSWORD}`).toString('base64');
async function dfs(path,body){const r=await fetch(`https://api.dataforseo.com/v3/dataforseo_labs/google/${path}`,{method:'POST',headers:{Authorization:`Basic ${auth()}`,'Content-Type':'application/json'},body:JSON.stringify([body])});const j=await r.json();if(!r.ok)throw new Error(j.status_message||j.error||'DataForSEO error');const t=j.tasks?.[0];if(!t||t.status_code>=40000)throw new Error(t?.status_message||'DataForSEO task failed');return t.result||[]}
function heuristicIntent(k){const x=k.toLowerCase();if(/\b(best|top|vs|versus|review|compare)\b/.test(x))return 'commercial';if(/\b(price|cost|buy|book|deal|offer|near me|hire|order)\b/.test(x))return 'transactional';if(/\b(how|what|why|when|guide|tips|ideas)\b/.test(x))return 'informational';return 'navigational'}
function normalize(x,seed){const kw=x.keyword||x.search_query||'';const sv=Number(x.search_volume??x.search_volume_last_month??0);return {keyword:kw.trim(),intent:x.search_intent?.main_intent||heuristicIntent(kw),intent_confidence:Number(x.search_intent?.probability||x.intent_probability||0),cluster:seed,parent_topic:x.parent_topic||seed,priority:sv,search_volume:sv,competition:x.competition??null,difficulty:x.difficulty??null,traffic_potential:Number(x.etv??x.traffic_potential??Math.round(sv*.3)),cpc:Number(x.cpc??0),trend:x.monthly_searches||x.search_volume_trend||[],source:x.source||'dataforseo_labs'};}
export async function GET(req){try{const siteId=new URL(req.url).searchParams.get('siteId');await requireSeoFeature(req,siteId,'keyword_research_enabled','seo-system.view');const {data,error}=await db().from('crm_seo_keywords').select('*').eq('site_id',siteId).eq('active',true).order('priority',{ascending:false}).limit(5000);if(error)throw error;return Response.json({ok:true,keywords:data||[]})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
export async function POST(req){
 try{
  const body=await req.json(),siteId=body.siteId,seed=String(body.seed||'').trim(),mode=body.mode||'suggestions',limit=Math.min(700,Math.max(1,Number(body.limit)||200)),location=body.location||'India',language=body.language||'en';
  const {site}=await requireSeoFeature(req,siteId,'keyword_research_enabled','seo-system.manage');
  if(!seed&&mode!=='site')throw new Error('seed is required');
  if(!process.env.DATAFORSEO_LOGIN||!process.env.DATAFORSEO_PASSWORD)throw new Error('DATAFORSEO credentials are required');
  let result=[];
  if(mode==='site'){result=await dfs('keywords_for_site/live',{target:new URL(site.domain).hostname,language_code:language,location_name:location,limit});}
  else if(mode==='ideas'){result=await dfs('keyword_ideas/live',{keywords:[seed],location_name:location,language_code:language,include_serp_info:true,limit});}
  else if(mode==='related'){result=await dfs('related_keywords/live',{keyword:seed,location_name:location,language_code:language,include_serp_info:true,limit});}
  else {result=await dfs('keyword_suggestions/live',{keyword:seed,location_name:location,language_code:language,include_serp_info:true,include_seed_keyword:true,limit});}
  const expanded=result.flatMap(x=>Array.isArray(x?.keywords)?x.keywords:x?.items||[x]).map(x=>normalize(x,seed)).filter(x=>x.keyword);
  const unique=[...new Map(expanded.map(x=>[x.keyword.toLowerCase(),x])).values()].slice(0,limit);
  const s=db();for(let i=0;i<unique.length;i+=200){const {error}=await s.from('crm_seo_keywords').upsert(unique.slice(i,i+200).map(x=>({...x,site_id:siteId,locale:language,country:site.locale?.split('-')[1]||'IN',device:body.device||'desktop',active:true})),{onConflict:'site_id,keyword'});if(error)throw error}
  // Provider intent enrichment for up to 1000 stored keywords
  const intents=await dfs('search_intent/live',{keywords:unique.slice(0,1000).map(x=>x.keyword),location_name:location,language_code:language});
  for(const i of intents.flatMap(x=>x.items||x.keywords||[x])){if(!i.keyword)continue;const intent=i.main_intent||i.search_intent;await s.from('crm_seo_keywords').update({intent:intent||heuristicIntent(i.keyword),intent_confidence:Number(i.probability||0)}).eq('site_id',siteId).eq('keyword',i.keyword)}
  return Response.json({ok:true,provider:'dataforseo_labs',mode,keywords:unique});
 }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
