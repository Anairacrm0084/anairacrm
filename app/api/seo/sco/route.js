import {db} from '../../../../lib/server/provider';
import {requireSeoFeature} from '../../../../lib/server/seoRuntime';

function norm(v=''){return String(v).trim().toLowerCase().replace(/[^a-z0-9\s-]/g,' ').replace(/\s+/g,' ')}
function slug(v=''){return norm(v).replace(/\s+/g,'-').slice(0,120)}
function tokenize(v=''){return [...new Set(norm(v).split(/\s+/).filter(x=>x.length>2))]}
function scoreOpportunity(row){let s=0;s+=Math.min(35,Number(row.search_volume||0)/100);s+=Math.min(25,Number(row.gap_score||0)/4);s+=row.has_target_page?0:20;s+=row.intent==='transactional'?15:row.intent==='commercial'?12:row.intent==='informational'?8:5;return Math.min(100,Math.round(s))}

export async function GET(req){try{const u=new URL(req.url),siteId=u.searchParams.get('siteId');if(!siteId)throw new Error('siteId is required');await requireSeoFeature(req,siteId,null,'seo-system.view');const s=db();const {data:rows,error}=await s.from('crm_seo_sco_opportunities').select('*').eq('site_id',siteId).order('opportunity_score',{ascending:false}).limit(500);if(error)throw error;const {data:runs}=await s.from('crm_seo_sco_runs').select('*').eq('site_id',siteId).order('created_at',{ascending:false}).limit(20);return Response.json({ok:true,opportunities:rows||[],runs:runs||[]})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}

export async function POST(req){try{const b=await req.json(),siteId=b.siteId;if(!siteId)throw new Error('siteId is required');await requireSeoFeature(req,siteId,null,'seo-system.manage');const s=db();
 const [{data:pages,error:pe},{data:keywords,error:ke},{data:gaps,error:ge},{data:competitors,error:ce}]=await Promise.all([
  s.from('crm_seo_pages').select('url,title,h1,word_count,indexable').eq('site_id',siteId).limit(5000),
  s.from('crm_seo_keywords').select('keyword,current_position,search_volume,intent,target_url').eq('site_id',siteId).eq('active',true).limit(5000),
  s.from('crm_seo_keyword_gap').select('*').eq('site_id',siteId).limit(5000),
  s.from('crm_seo_competitors').select('domain').eq('site_id',siteId).eq('active',true).limit(100)
 ]);if(pe)throw pe;if(ke)throw ke;if(ge)throw ge;if(ce)throw ce;
 const pageText=(pages||[]).map(p=>norm(`${p.url} ${p.title||''} ${p.h1||''}`)).join(' ');
 const candidates=new Map();
 for(const k of keywords||[]){const keyword=String(k.keyword||'').trim();if(!keyword)continue;const hasTarget=Boolean(k.target_url)||pageText.includes(norm(keyword));const key=norm(keyword);candidates.set(key,{keyword,search_volume:k.search_volume||null,gap_score:k.current_position==null?80:Math.max(0,100-Number(k.current_position||100)),intent:k.intent||'unknown',target_url:k.target_url||null,has_target_page:hasTarget,source:'keyword_index'});}
 for(const g of gaps||[]){const keyword=String(g.keyword||'').trim();if(!keyword)continue;const key=norm(keyword);const prev=candidates.get(key)||{};candidates.set(key,{...prev,keyword,search_volume:g.search_volume||prev.search_volume||null,gap_score:Number(g.opportunity_score||g.gap_score||80),intent:g.intent||prev.intent||'unknown',target_url:g.target_url||prev.target_url||null,has_target_page:Boolean(g.target_url)||Boolean(prev.has_target_page),source:'keyword_gap'});}
 const rows=[...candidates.values()].map(x=>({...x,opportunity_score:scoreOpportunity(x),recommended_action:x.has_target_page?'optimize_existing_page':'create_new_content',recommended_slug:slug(x.keyword)})).filter(x=>x.opportunity_score>=20).sort((a,b)=>b.opportunity_score-a.opportunity_score).slice(0,500);
 const now=new Date().toISOString();const {data:run,error:re}=await s.from('crm_seo_sco_runs').insert({site_id:siteId,status:'completed',source_summary:{pages:(pages||[]).length,keywords:(keywords||[]).length,gaps:(gaps||[]).length,competitors:(competitors||[]).length},candidate_count:rows.length,created_at:now,completed_at:now}).select().single();if(re)throw re;
 if(rows.length){const {error:ue}=await s.from('crm_seo_sco_opportunities').upsert(rows.map(x=>({...x,site_id:siteId,run_id:run.id,updated_at:now})),{onConflict:'site_id,keyword'});if(ue)throw ue;}
 return Response.json({ok:true,run,opportunities:rows});
 }catch(e){return Response.json({ok:false,error:e.message},{status:e.status||500})}}
