import crypto from 'node:crypto';
import {db} from './provider';

export const MARKET_PARITY_VERSION='2026.09.26-market-parity-v2';
const sha=v=>crypto.createHash('sha256').update(String(v||'')).digest('hex');
const now=()=>new Date().toISOString();

export const CAPABILITIES={
 webIndex:['url discovery','html fetch','js rendering','content extraction','link graph','page index','historical snapshots','custom xpath','custom css','custom regex','custom javascript','accessibility extraction','crawl checkpointing','distributed crawl','dead letter queue'],
 technicalAudit:['300+ technical checks','javascript crawler','chromium rendering','accessibility','international seo','amp','security','crawl visualization','custom extraction'],
 keywords:['keyword database','historical volume','serp database','intent','difficulty','cpc','trends','seasonality','questions','autocomplete','clusters'],
 serp:['google','bing','maps','ai results','serp snapshots','features','competitors','citations','visibility','share of voice'],
 backlinks:['backlink index','referring domains','history','freshness','authority','risk','traffic estimate','link intersect','lost link recovery'],
 local:['local grid','geo coordinates','radius scanning','competitor maps','citation discovery','citation submission','review monitoring','review generation','gbp audit','gbp posting'],
 content:['serp corpus','competitor nlp','term frequency','topic coverage','semantic similarity','content score','ai search score','entity salience','realtime scoring'],
 deployment:['wordpress','apache','nginx','cloudflare','vercel','dns cdn','rollback','verification','monitoring'],
 automation:['visual workflow','branching','conditions','parallel execution','dependency graph','queue','dead letter','provider retry','circuit breaker','observability'],
 reporting:['report builder','drag drop blocks','custom kpis','client portal','share links','read only dashboards','narrative generation','email delivery','delivery analytics','portfolio reports'],
 provider:['latency','usage','quota','rate limits','cost','request history','sla','failover','automatic switching','credential rotation','expiry alerts'],
 agency:['workspace','client portal','white label domain','custom branding','custom sender','billing','seat management','onboarding','lead generation','client tasks'],
 revenue:['seo to crm','lead attribution','customer 360','booking attribution','hotel revenue','restaurant revenue','content revenue','keyword revenue','seo roi']
};

export function capabilityCatalog(){return Object.entries(CAPABILITIES).flatMap(([category,items])=>items.map(capability=>({category,capability,requiredLayers:['data','security','runtime','ui','provider','persistence','recovery','e2e','build','docs']})))}

export async function recordProviderTelemetry({siteId,provider,operation,started,statusCode=200,success=true,cost=null,errorClass=null,metadata={}}){
 const s=db();
 const latency_ms=Math.max(0,Date.now()-started);
 await s.from('crm_seo_provider_telemetry').insert({site_id:siteId||null,provider,operation,latency_ms,status_code:statusCode,success,cost,error_class:errorClass,metadata});
 return latency_ms;
}

export async function providerFetch({siteId,provider,operation,url,options={},parse='json',retries=2}){
 const started=Date.now();
 let lastError=null;
 for(let attempt=0;attempt<=retries;attempt++){
  try{
   const controller=new AbortController();
   const timeout=setTimeout(()=>controller.abort(),Number(options.timeoutMs||30000));
   const {timeoutMs,...requestOptions}=options;
   const r=await fetch(url,{...requestOptions,signal:requestOptions.signal||controller.signal});
   clearTimeout(timeout);
   const value=parse==='text'?await r.text():await r.json().catch(()=>({}));
   await recordProviderTelemetry({siteId,provider,operation,started,statusCode:r.status,success:r.ok,metadata:{url,method:requestOptions.method||'GET',attempt}});
   if(!r.ok){const e=new Error(value?.error||value?.message||`Provider ${provider} returned ${r.status}`);e.status=r.status;e.provider=provider;throw e;}
   return value;
  }catch(e){
   lastError=e;
   if(attempt>=retries || (e.status && ![408,425,429,500,502,503,504].includes(e.status))) break;
   await new Promise(r=>setTimeout(r,Math.min(4000,250*Math.pow(2,attempt))));
  }
 }
 await recordProviderTelemetry({siteId,provider,operation,started,statusCode:lastError?.status||0,success:false,errorClass:lastError?.name||'provider_error',metadata:{message:lastError?.message,retries}});
 throw lastError;
}

export function dataForSeoConfigured(){return Boolean(process.env.DATAFORSEO_LOGIN&&process.env.DATAFORSEO_PASSWORD)}
export function serpApiConfigured(){return Boolean(process.env.SERPAPI_KEY)}
export function openAIConfigured(){return Boolean(process.env.OPENAI_API_KEY)}
export function browserConfigured(){return Boolean(process.env.BROWSERLESS_API_TOKEN)}

export async function keywordResearch({siteId,keyword,location='India',language='en',device='desktop'}){
 if(!keyword?.trim()) throw new Error('keyword is required');
 const locale=`${language}-${String(location).toLowerCase()==='india'?'IN':'US'}`;
 if(dataForSeoConfigured()) {
  const auth=Buffer.from(`${process.env.DATAFORSEO_LOGIN}:${process.env.DATAFORSEO_PASSWORD}`).toString('base64');
  const locationCode=Number(process.env.DATAFORSEO_LOCATION_CODE||2840);
  const endpoint='https://api.dataforseo.com/v3/dataforseo_labs/google/keyword_suggestions/live';
  const payload=[{keywords:[keyword.trim()],location_code:locationCode,language_code:process.env.DATAFORSEO_LANGUAGE_CODE||language,include_seed_keyword:true,limit:1000}];
  const j=await providerFetch({siteId,provider:'dataforseo',operation:'keyword_suggestions',url:endpoint,options:{method:'POST',headers:{Authorization:`Basic ${auth}`,'content-type':'application/json'},body:JSON.stringify(payload)}});
  const rows=(j.tasks?.[0]?.result||[]).flatMap(x=>x.items||[]).map(x=>{const d=x.keyword_data||x;return {keyword:d.keyword||x.keyword,volume:d.keyword_info?.search_volume??d.search_volume??null,difficulty:d.keyword_properties?.keyword_difficulty??d.keyword_difficulty??null,cpc:d.keyword_info?.cpc??d.cpc??null,intent:d.search_intent_info?.main_intent||null,trend:d.keyword_info?.monthly_searches||[],source:'dataforseo',source_ref:x.id||null,locale}}).filter(x=>x.keyword);
  if(rows.length) await db().from('crm_seo_keyword_index').upsert(rows.map(x=>({site_id:siteId,...x,observed_at:new Date().toISOString()})),{onConflict:'site_id,keyword,locale,device'});
  return {provider:'dataforseo',configured:true,keyword,location,language,device,results:rows,raw:j};
 }
 if(serpApiConfigured()){
  const p=new URL('https://serpapi.com/search.json');p.searchParams.set('engine','google');p.searchParams.set('q',keyword);p.searchParams.set('location',location);p.searchParams.set('hl',language);p.searchParams.set('device',device);p.searchParams.set('api_key',process.env.SERPAPI_KEY);
  const j=await providerFetch({siteId,provider:'serpapi',operation:'keyword_research',url:p.toString()});
  const rows=(j.related_searches||[]).map(x=>x.query).filter(Boolean).map(k=>({keyword:k,source:'serpapi',locale,device,questions:j.related_questions||[],related:j.related_searches||[]}));
  if(rows.length) await db().from('crm_seo_keyword_index').upsert(rows.map(x=>({site_id:siteId,...x,observed_at:new Date().toISOString()})),{onConflict:'site_id,keyword,locale,device'});
  return {provider:'serpapi',configured:true,keyword,location,language,device,results:rows,search_information:j.search_information||{},serp_features:{local_pack:Boolean(j.local_results),paa:(j.related_questions||[]).length}};
 }
 return {provider:'none',configured:false,keyword,location,language,device,results:[],error:'Configure DataForSEO or SerpAPI to execute live keyword research.'};
}

export async function serpSnapshot({siteId,keyword,location='India',device='desktop',engine='google'}){
 if(!serpApiConfigured()) return {provider:'serpapi',configured:false,keyword,location,device,engine};
 const p=new URL('https://serpapi.com/search.json');p.searchParams.set('engine',engine==='bing'?'bing':'google');p.searchParams.set('q',keyword);p.searchParams.set('location',location);p.searchParams.set('device',device);p.searchParams.set('api_key',process.env.SERPAPI_KEY);
 const j=await providerFetch({siteId,provider:'serpapi',operation:'serp_snapshot',url:p.toString()});
 const rows=(j.organic_results||[]).map(x=>({position:x.position,url:x.link,domain:x.displayed_link||new URL(x.link).hostname,title:x.title,snippet:x.snippet||'',feature:'organic'}));
 const s=db(); if(siteId&&rows.length) await s.from('crm_seo_serp_index').insert(rows.map(x=>({site_id:siteId,keyword,engine,locale:location,device,...x,provider:'serpapi',raw:x})));
 return {provider:'serpapi',configured:true,rows,features:{local:Boolean(j.local_results),paa:j.related_questions||[],featured:j.answer_box||null},raw:j};
}

export async function contentScore({siteId,url,keyword,html}){
 const text=String(html||'').replace(/<script[\s\S]*?<\/script>/gi,' ').replace(/<style[\s\S]*?<\/style>/gi,' ').replace(/<[^>]+>/g,' ').replace(/\s+/g,' ').trim();
 const words=text.toLowerCase().split(/\s+/).filter(Boolean); const target=String(keyword||'').toLowerCase().trim();
 const occurrences=target?words.filter(w=>w.includes(target)).length:0; const density=words.length?occurrences/words.length*100:0;
 const seo_score=Math.max(0,Math.min(100,50+(Math.min(words.length,1800)/1800)*25+Math.min(density*10,15)+(target?10:0)));
 const headings=[...String(html||'').matchAll(/<h[1-6][^>]*>([\s\S]*?)<\/h[1-6]>/gi)].map(m=>m[1].replace(/<[^>]+>/g,' ').trim()).filter(Boolean);
 const title=(String(html||'').match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1]||'').trim();
 const description=(String(html||'').match(/<meta[^>]+name=[\"']description[\"'][^>]+content=[\"']([^\"']*)/i)?.[1]||'').trim();
 const covered=new Set(headings.join(' ').toLowerCase().split(/\W+/).filter(x=>x.length>3));
 const topical=target?Math.min(100,Math.round(([...new Set(target.split(/\W+/).filter(x=>x.length>2))].filter(x=>covered.has(x)).length/Math.max(1,target.split(/\W+/).filter(x=>x.length>2).length))*100)):Math.min(100,words.length/1200*100);
 const semantic=target?Math.min(1,(occurrences/Math.max(1,words.length))*120):0;
 const entitySalience=Math.min(1,(new Set((title+' '+headings.join(' ')).toLowerCase().split(/\W+/).filter(x=>x.length>4)).size)/80);
 const aiScore=Math.min(100,seo_score*0.55+topical*0.25+semantic*20+entitySalience*20);
 const result={url,keyword,seo_score:Number(seo_score.toFixed(2)),ai_search_score:Number(aiScore.toFixed(2)),topical_coverage:Number(topical.toFixed(2)),semantic_similarity:Number(semantic.toFixed(4)),entity_salience:Number(entitySalience.toFixed(4)),term_frequency:{[target]:occurrences},competitor_benchmark:{title_length:title.length,description_length:description.length,headings:headings.length,word_count:words.length},recommendations:[]};
 if(words.length<500)result.recommendations.push('Expand useful topical coverage with original, intent-matched information.');
 if(target&&!occurrences)result.recommendations.push('Add the target concept naturally where it is genuinely relevant.');
 if(siteId)await db().from('crm_seo_content_scores').insert({site_id:siteId,...result,term_frequency:result.term_frequency,recommendations:result.recommendations});
 return result;
}

export async function certificationSeed(siteId){
 const s=db(); const rows=capabilityCatalog().flatMap(x=>x.requiredLayers.map(layer=>({site_id:siteId,version:MARKET_PARITY_VERSION,category:x.category,capability:x.capability,layer,status:'not_started'})));
 if(rows.length) await s.from('crm_seo_market_certification').upsert(rows,{onConflict:'site_id,version,category,capability,layer'});
 return {version:MARKET_PARITY_VERSION,total:rows.length};
}

export async function certificationSummary(siteId){
 const s=db(); const {data,error}=await s.from('crm_seo_market_certification').select('*').eq('site_id',siteId).eq('version',MARKET_PARITY_VERSION); if(error)throw error;
 const rows=data||[], total=rows.length, verified=rows.filter(x=>x.status==='production_certified').length;
 return {version:MARKET_PARITY_VERSION,total,verified,percentage:total?Number((verified/total*100).toFixed(2)):0,blocking:rows.filter(x=>x.status!=='production_certified').slice(0,100)};
}

export function providerMatrix(){return [
 {provider:'Browserless',configured:browserConfigured(),capabilities:['js_rendering','chromium','screenshots']},
 {provider:'SerpAPI',configured:serpApiConfigured(),capabilities:['serp','rank','local']},
 {provider:'DataForSEO',configured:dataForSeoConfigured(),capabilities:['keyword','serp','backlinks']},
 {provider:'OpenAI',configured:openAIConfigured(),capabilities:['ai_content','geo','recommendations']},
 {provider:'Google GSC/GA4',configured:Boolean(process.env.GOOGLE_CLIENT_ID&&process.env.GOOGLE_CLIENT_SECRET),capabilities:['gsc','ga4','oauth']}
]}
