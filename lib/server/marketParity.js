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



export async function keywordIntelligence({siteId,seed,location='India',language='en',device='desktop',limit=200}){
 const q=String(seed||'').trim(); if(!q) throw new Error('seed is required');
 const out={provider:null,configured:false,seed:q,autocomplete:[],questions:[],related:[],suggestions:[]};
 if(dataForSeoConfigured()){
  const auth=Buffer.from(`${process.env.DATAFORSEO_LOGIN}:${process.env.DATAFORSEO_PASSWORD}`).toString('base64');
  const headers={Authorization:`Basic ${auth}`,'content-type':'application/json'};
  const locationName=location||'India';
  const calls=[
   ['keyword_suggestions/live',{keyword:q,location_name:locationName,language_code:language,include_serp_info:true,limit}],
   ['related_keywords/live',{keyword:q,location_name:locationName,language_code:language,include_serp_info:true,limit}]
  ];
  const results=[];
  for(const [path,body] of calls){
   const j=await providerFetch({siteId,provider:'dataforseo',operation:path,url:`https://api.dataforseo.com/v3/dataforseo_labs/google/${path}`,options:{method:'POST',headers,body:JSON.stringify([body])}});
   results.push(...(j.tasks?.[0]?.result||[]).flatMap(x=>x.items||x.keywords||[x]));
  }
  const normalized=results.map(x=>x.keyword_data||x).map(x=>String(x.keyword||x.search_query||'').trim()).filter(Boolean);
  out.provider='dataforseo';out.configured=true;out.suggestions=[...new Set(normalized)].slice(0,limit);out.related=out.suggestions.filter(x=>x.toLowerCase()!==q.toLowerCase()).slice(0,limit);
  out.questions=out.related.filter(x=>/^(who|what|where|when|why|how|can|is|are|do|does|which|best|near)/i.test(x)).slice(0,limit);
 } else if(serpApiConfigured()){
  const u=new URL('https://serpapi.com/search.json');u.searchParams.set('engine','google');u.searchParams.set('q',q);u.searchParams.set('location',location);u.searchParams.set('hl',language);u.searchParams.set('device',device);u.searchParams.set('api_key',process.env.SERPAPI_KEY);
  const j=await providerFetch({siteId,provider:'serpapi',operation:'keyword_intelligence',url:u.toString()});
  out.provider='serpapi';out.configured=true;out.related=[...(j.related_searches||[])].map(x=>x.query).filter(Boolean).slice(0,limit);out.questions=[...(j.related_questions||[])].map(x=>x.question||x.query).filter(Boolean).slice(0,limit);out.autocomplete=[...(j.autocomplete_results||[])].map(x=>x.value||x.query||x).filter(Boolean).slice(0,limit);out.suggestions=[...new Set([...out.related,...out.questions,...out.autocomplete])].slice(0,limit);
 } else return {...out,error:'Configure DataForSEO or SerpAPI for keyword intelligence.'};
 if(siteId&&out.suggestions.length) await db().from('crm_seo_keyword_index').upsert(out.suggestions.map(keyword=>({site_id:siteId,keyword,locale:`${language}-${String(location).toUpperCase()==='INDIA'?'IN':'US'}`,device,questions:out.questions,related:out.related,source:out.provider,observed_at:new Date().toISOString()})),{onConflict:'site_id,keyword,locale,device'});
 return out;
}

export async function backlinkGap({siteId,competitorDomain,limit=500}){
 if(!dataForSeoConfigured()) return {configured:false,provider:'dataforseo',error:'Configure DataForSEO for backlink gap analysis.',rows:[]};
 const {data:site}=await db().from('crm_seo_sites').select('domain').eq('id',siteId).single();
 const target=String(site?.domain||'').replace(/^https?:\/\//,'').replace(/^www\./,'').split('/')[0];
 const competitor=String(competitorDomain||'').replace(/^https?:\/\//,'').replace(/^www\./,'').split('/')[0];
 if(!competitor) throw new Error('competitorDomain is required');
 const auth=Buffer.from(`${process.env.DATAFORSEO_LOGIN}:${process.env.DATAFORSEO_PASSWORD}`).toString('base64');
 const headers={Authorization:`Basic ${auth}`,'content-type':'application/json'};
 const task=await providerFetch({siteId,provider:'dataforseo',operation:'backlink_gap',url:'https://api.dataforseo.com/v3/backlinks/bulk_backlinks/live',options:{method:'POST',headers,body:JSON.stringify([{targets:[target,competitor],include_subdomains:true,exclude_internal_backlinks:true,limit:Math.min(1000,limit)}])}});
 const raw=task.tasks?.[0]?.result||task.result||[];const rows=[];for(const x of raw.flatMap(x=>x.items||x.backlinks||[x])){const source=x.url_from||x.source_url||x.referring_url;const domains=(x.domain_from||x.referring_domain||'').replace(/^www\./,'');if(domains&&domains===competitor)continue;rows.push({source_url:source||null,referring_domain:domains||null,target_url:x.url_to||x.target_url||null,authority:x.domain_from_rank??x.rank??null,anchor_text:x.anchor||x.anchor_text||null,competitor_only:true,raw:x});}
 return {configured:true,provider:'dataforseo',target,competitor,rows:rows.slice(0,limit)};
}

export async function serpVisibility({siteId,keyword,location='India',device='desktop',engine='google'}){
 const snap=await serpSnapshot({siteId,keyword,location,device,engine});
 if(!snap.configured) return {...snap,visibility:0,shareOfVoice:0};
 const rows=snap.rows||[];const visible=rows.filter(x=>x.position!=null);const weighted=visible.reduce((sum,x)=>sum+(101-Number(x.position||101)),0);const own=rows.find(x=>x.domain&&siteId&&x.url);
 const {data:site}=await db().from('crm_seo_sites').select('domain').eq('id',siteId).maybeSingle();let ownPositions=[];if(site){const host=new URL(site.domain.startsWith('http')?site.domain:`https://${site.domain}`).hostname.replace(/^www\./,'');ownPositions=rows.filter(x=>{try{return new URL(x.url).hostname.replace(/^www\./,'')===host}catch{return false}}).map(x=>x.position)}
 const best=ownPositions.length?Math.min(...ownPositions):null;const ownWeight=best!=null?101-best:0;const share=weighted?Number((ownWeight/weighted*100).toFixed(2)):0;const visibility=best!=null?Number((101-best).toFixed(2)):0;
 await db().from('crm_seo_serp_snapshots').insert({site_id:siteId,keyword,location,device,provider:snap.provider,position:best,visibility,share_of_voice:share,features:snap.features,competitors:rows.filter(x=>!ownPositions.includes(x.position)).slice(0,20),results:rows,raw_provider:snap.raw});
 return {...snap,position:best,visibility,shareOfVoice:share};
}

export async function geoProviderRun({siteId,prompt,provider,model}){
 const q=String(prompt||'').trim();if(!q)throw new Error('prompt is required');
 if(provider==='openai'){
  if(!openAIConfigured())throw new Error('OPENAI_API_KEY is required');
  const j=await providerFetch({siteId,provider:'openai',operation:'geo_visibility',url:'https://api.openai.com/v1/responses',options:{method:'POST',headers:{Authorization:`Bearer ${process.env.OPENAI_API_KEY}`,'content-type':'application/json'},body:JSON.stringify({model:model||process.env.OPENAI_MODEL||'gpt-5-mini',tools:[{type:'web_search'}],input:q})}});
  const answer=j.output_text||'';return {provider:'openai',model:model||process.env.OPENAI_MODEL||'gpt-5-mini',answer,citations:[...new Set((j.output||[]).flatMap(x=>x.content||[]).flatMap(x=>x.annotations||[]).map(x=>x.url).filter(Boolean))],raw:j};
 }
 if(provider==='gemini'){
  if(!process.env.GEMINI_API_KEY)throw new Error('GEMINI_API_KEY is required');
  const modelName=model||process.env.GEMINI_MODEL||'gemini-2.5-flash';const u=`https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${encodeURIComponent(process.env.GEMINI_API_KEY)}`;
  const j=await providerFetch({siteId,provider:'gemini',operation:'geo_visibility',url:u,options:{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({contents:[{parts:[{text:q}]}]})}});
  const answer=j.candidates?.[0]?.content?.parts?.map(x=>x.text||'').join('')||'';return {provider:'gemini',model:modelName,answer,citations:[],raw:j};
 }
 if(provider==='anthropic'){
  if(!process.env.ANTHROPIC_API_KEY)throw new Error('ANTHROPIC_API_KEY is required');
  const modelName=model||process.env.ANTHROPIC_MODEL||'claude-sonnet-4-5';const j=await providerFetch({siteId,provider:'anthropic',operation:'geo_visibility',url:'https://api.anthropic.com/v1/messages',options:{method:'POST',headers:{'x-api-key':process.env.ANTHROPIC_API_KEY,'anthropic-version':'2023-06-01','content-type':'application/json'},body:JSON.stringify({model:modelName,max_tokens:2000,messages:[{role:'user',content:q}]})}});
  const answer=j.content?.map(x=>x.text||'').join('')||'';return {provider:'anthropic',model:modelName,answer,citations:[],raw:j};
 }
 throw new Error(`Unsupported GEO provider: ${provider}`);
}

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
