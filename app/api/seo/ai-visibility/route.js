import {db} from '../../../../lib/server/provider';
import {requireSeoFeature} from '../../../../lib/server/seoRuntime';

function normHost(v){try{return new URL(v).hostname.replace(/^www\./,'').toLowerCase()}catch{return String(v||'').toLowerCase().replace(/^www\./,'')}}
function mentions(text,needle){const a=String(text||'').toLowerCase(),b=String(needle||'').toLowerCase().trim();if(!b)return 0;return (a.match(new RegExp(b.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length}
function collectCitations(ai){const out=[];const push=u=>{if(!u)return;try{const x=new URL(typeof u==='string'?u:(u.url||u.link||''));if(/^https?:$/.test(x.protocol))out.push(x.href)}catch{}};
  for(const x of ai?.references||[])push(x);for(const x of ai?.sources||[])push(x);for(const x of ai?.links||[])push(x);for(const x of ai?.text_blocks||[])for(const y of x?.references||[])push(y);return [...new Set(out)].slice(0,100)}
async function serp(q){
  if(!process.env.SERPAPI_KEY)throw new Error('SERPAPI_KEY is required for Google AI Overview visibility checks');
  const u=new URL('https://serpapi.com/search.json');u.searchParams.set('engine','google');u.searchParams.set('q',q);u.searchParams.set('api_key',process.env.SERPAPI_KEY);u.searchParams.set('hl','en');u.searchParams.set('gl','in');u.searchParams.set('num','100');
  const r=await fetch(u);const j=await r.json();if(!r.ok)throw new Error(j.error||'SerpAPI Google search failed');
  let ai=j.ai_overview||null;
  if(ai?.page_token){const a=new URL('https://serpapi.com/search.json');a.searchParams.set('engine','google_ai_overview');a.searchParams.set('page_token',ai.page_token);a.searchParams.set('api_key',process.env.SERPAPI_KEY);const rr=await fetch(a);const jj=await rr.json();if(rr.ok)ai=jj.ai_overview||jj;}
  const text=[ai?.text,ai?.answer,ai?.snippet, ...(ai?.text_blocks||[]).map(x=>x?.snippet||x?.text||x?.content||'')].filter(Boolean).join('\n');
  const citations=collectCitations(ai);
  return {raw:j,ai,text,citations};
}
async function openaiWeb(q){
  if(!process.env.OPENAI_API_KEY)throw new Error('OPENAI_API_KEY is required for optional web-grounded visibility analysis');
  const r=await fetch('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${process.env.OPENAI_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({model:process.env.OPENAI_MODEL||'gpt-5-mini',tools:[{type:'web_search'}],input:q})});
  const j=await r.json();if(!r.ok)throw new Error(j.error?.message||'OpenAI web search failed');
  const answer=j.output_text||'';const citations=[];for(const item of j.output||[])for(const c of item.content||[])for(const a of c.annotations||[])if(a.url)citations.push(a.url);return {answer,citations:[...new Set(citations)]};
}
export async function GET(req){try{const siteId=new URL(req.url).searchParams.get('siteId');await requireSeoFeature(req,siteId,'geo_visibility_enabled');const s=db();const [p,r]=await Promise.all([s.from('crm_seo_ai_visibility_prompts').select('*').eq('site_id',siteId).order('created_at',{ascending:false}),s.from('crm_seo_ai_visibility_runs').select('*').eq('site_id',siteId).order('created_at',{ascending:false}).limit(500)]);return Response.json({ok:true,prompts:p.data||[],runs:r.data||[]})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
export async function POST(req){const started=Date.now();try{
  const {siteId,prompt,promptId,provider='serpapi_google_ai_overview'}=await req.json();const {site}=await requireSeoFeature(req,siteId,'geo_visibility_enabled');const s=db();let p=prompt;
  if(promptId){const {data}=await s.from('crm_seo_ai_visibility_prompts').select('*').eq('id',promptId).eq('site_id',siteId).single();p=data?.prompt}
  if(!p)throw new Error('prompt is required');const brand=site.brand_name||normHost(site.domain);const host=normHost(site.domain);let answer='',citations=[],raw={},used=provider,competitorMentions=[];
  if(provider==='serpapi_google_ai_overview'){const x=await serp(p);answer=x.text;citations=x.citations;raw=x.raw;const organic=x.raw?.organic_results||[];const refs=[...new Set(organic.map(r=>normHost(r.link)).filter(Boolean))];competitorMentions=refs.filter(d=>d!==host&&d!==normHost(brand)).slice(0,20).map(domain=>({domain,mentions:1}));
  } else if(provider==='openai_web_search'){const x=await openaiWeb(p);answer=x.answer;citations=x.citations;raw={citations};used='openai_web_search';}
  else throw new Error('Unsupported AI visibility provider');
  const mentionCount=mentions(answer,brand)||mentions(answer,host);const brandMentioned=mentionCount>0;const citedBrand=citations.filter(u=>normHost(u)===host||normHost(u).endsWith('.'+host));const score=Math.min(100,Math.round((brandMentioned?50:0)+(citedBrand.length?50:0)));
  const row={site_id:siteId,prompt_id:promptId||null,provider:used,model:provider==='serpapi_google_ai_overview'?'google_ai_overview':'openai-web-search',answer,brand_mentioned:brandMentioned,mention_count:mentionCount,competitor_mentions:competitorMentions,citations,status:'completed',visibility_score:score,confidence:citations.length?0.9:0.6,created_at:new Date().toISOString()};
  const {data,error}=await s.from('crm_seo_ai_visibility_runs').insert(row).select().single();if(error)throw error;await s.from('crm_seo_provider_health').upsert({site_id:siteId,provider:used,status:'configured',checked_at:new Date().toISOString(),latency_ms:Date.now()-started,last_error:null,metadata:{citationCount:citations.length,brandCitations:citedBrand.length}},{onConflict:'site_id,provider'});
  return Response.json({ok:true,provider:used,run:data});
}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
