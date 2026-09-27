import {NextResponse} from 'next/server';
import {db} from '../../../../lib/server/provider';
import {MARKET_PARITY_VERSION,capabilityCatalog,certificationSeed,certificationSummary,contentScore,keywordResearch,providerMatrix,serpSnapshot,providerFetch} from '../../../../lib/server/marketParity';
import {requireSeoFeature} from '../../../../lib/server/seoRuntime';

async function body(req){return await req.json().catch(()=>({}))}
export async function GET(req){
 try{
  const u=new URL(req.url),siteId=u.searchParams.get('siteId'),action=u.searchParams.get('action')||'summary'; if(!siteId)return NextResponse.json({ok:false,error:'siteId is required'},{status:400});
  await requireSeoFeature(req,siteId,null,'seo-system.view');
  if(action==='providers')return NextResponse.json({ok:true,providers:providerMatrix()});
  if(action==='catalog')return NextResponse.json({ok:true,version:MARKET_PARITY_VERSION,catalog:capabilityCatalog()});
  if(action==='certification')return NextResponse.json({ok:true,...await certificationSummary(siteId)});
  const s=db();
  const tables=['crm_seo_web_index_pages','crm_seo_keyword_index','crm_seo_serp_index','crm_seo_backlink_index','crm_seo_local_grid_runs','crm_seo_citation_records','crm_seo_competitor_intelligence','crm_seo_content_scores','crm_seo_provider_telemetry','crm_seo_revenue_attribution'];
  const counts={}; for(const t of tables){const {count}=await s.from(t).select('*',{count:'exact',head:true}).eq('site_id',siteId);counts[t]=count||0;}
  return NextResponse.json({ok:true,counts,providers:providerMatrix(),certification:await certificationSummary(siteId)});
 }catch(e){return NextResponse.json({ok:false,error:e.message},{status:500})}
}
export async function POST(req){
 try{
  const b=await body(req),siteId=b.siteId,action=b.action||'seed'; if(!siteId)return NextResponse.json({ok:false,error:'siteId is required'},{status:400});
  await requireSeoFeature(req,siteId,null,'seo-system.manage');
  if(action==='seed')return NextResponse.json({ok:true,...await certificationSeed(siteId)});
  if(action==='keyword')return NextResponse.json({ok:true,result:await keywordResearch({siteId,keyword:b.keyword,location:b.location,language:b.language,device:b.device})});
  if(action==='serp')return NextResponse.json({ok:true,result:await serpSnapshot({siteId,keyword:b.keyword,location:b.location,device:b.device,engine:b.engine})});
  if(action==='content-score')return NextResponse.json({ok:true,result:await contentScore({siteId,url:b.url,keyword:b.keyword,html:b.html})});
  if(action==='sync-index'){
   const s=db();
   const [{data:pages,error:pe},{data:links,error:le},{data:backs,error:be},{data:cits,error:ce}]=await Promise.all([
    s.from('crm_seo_pages').select('*').eq('site_id',siteId),s.from('crm_seo_crawl_links').select('*').eq('site_id',siteId),
    s.from('crm_seo_backlinks').select('*').eq('site_id',siteId),s.from('crm_seo_local_citations').select('*').eq('site_id',siteId)
   ]);
   if(pe)throw pe;if(le)throw le;if(be)throw be;if(ce)throw ce;
   if(pages?.length)await s.from('crm_seo_web_index_pages').upsert(pages.map(x=>({site_id:siteId,url:x.url,normalized_url:x.url,status_code:x.http_status||x.status,content_hash:x.content_hash||null,word_count:x.word_count||0,crawl_depth:x.crawl_depth||0,last_crawled_at:x.last_crawled_at||new Date().toISOString(),extracted:{title:x.title,meta_description:x.meta_description,canonical:x.canonical,indexable:x.indexable},snapshot:{source:'crm_seo_pages'}})),{onConflict:'site_id,normalized_url'});
   if(links?.length)await s.from('crm_seo_web_index_links').upsert(links.map(x=>({site_id:siteId,source_url:x.source_url,target_url:x.target_url,anchor_text:x.anchor_text,rel:x.rel||null,attributes:x.attributes||{}})),{onConflict:'site_id,source_url,target_url,anchor_text'});
   if(backs?.length)await s.from('crm_seo_backlink_index').upsert(backs.map(x=>{const source=x.source_url||x.referring_url||'',target=x.target_url||x.url||'';return {site_id:siteId,source_url:source,target_url:target,normalized_source_url:source.trim().toLowerCase(),normalized_target_url:target.trim().toLowerCase(),source_domain:x.source_domain||x.referring_domain,anchor:x.anchor||x.anchor_text,rel:x.rel,status:x.status||'active',first_seen_at:x.first_seen_at,last_seen_at:x.last_seen_at||new Date().toISOString(),authority:x.authority||x.domain_authority,risk:x.risk,traffic_estimate:x.traffic_estimate,provider:x.provider,raw:x}}).filter(x=>x.source_url&&x.target_url),{onConflict:'site_id,normalized_source_url,normalized_target_url'});
   if(cits?.length)await s.from('crm_seo_citation_records').upsert(cits.map(x=>({site_id:siteId,directory:x.directory||x.source_name||'unknown',listing_url:x.url||x.listing_url,business_name:x.business_name,address:x.address,phone:x.phone,status:x.status||'discovered',raw:x})),{onConflict:'site_id,directory,listing_url'});
   return NextResponse.json({ok:true,synced:{pages:pages?.length||0,links:links?.length||0,backlinks:backs?.length||0,citations:cits?.length||0}});
  }
  if(action==='revenue'){
   const s=db();const {data,error}=await s.from('crm_seo_revenue_attribution').insert({site_id:siteId,keyword:b.keyword||null,landing_page:b.landingPage||null,visitor_id:b.visitorId||null,lead_id:b.leadId||null,customer_id:b.customerId||null,booking_id:b.bookingId||null,transaction_id:b.transactionId||null,conversion_type:b.conversionType||'booking',revenue:Number(b.revenue||0),currency:b.currency||'INR',attribution_model:b.attributionModel||'last_non_direct',metadata:b.metadata||{}}).select('*').single();if(error)throw error;return NextResponse.json({ok:true,row:data});
  }
  if(action==='deployment-target'){
   const s=db();const {data,error}=await s.from('crm_seo_deployment_targets_v2').upsert({site_id:siteId,target_type:b.targetType,name:b.name,endpoint:b.endpoint||null,credentials_ref:b.credentialsRef||null,enabled:b.enabled!==false,config:b.config||{}},{onConflict:'site_id,target_type,name'}).select('*').single();if(error)throw error;return NextResponse.json({ok:true,row:data});
  }
  if(action==='local-grid'){
   if(!b.keyword)throw new Error('keyword is required');
   const grid=Math.max(1,Math.min(9,Number(b.gridSize)||3)), radius=Math.max(0,Number(b.radiusM)||1000), lat=Number(b.lat), lng=Number(b.lng);
   const points=[];
   for(let y=0;y<grid;y++)for(let x=0;x<grid;x++){const dy=grid===1?0:(y-(grid-1)/2)/((grid-1)/2);const dx=grid===1?0:(x-(grid-1)/2)/((grid-1)/2);points.push({row:y,col:x,lat:Number.isFinite(lat)?lat+dy*(radius/111320):null,lng:Number.isFinite(lng)?lng+dx*(radius/(111320*Math.max(.2,Math.cos((lat||0)*Math.PI/180)))):null});}
   const results=[];
   for(const point of points){
    let result;
    if(point.lat!==null&&point.lng!==null&&process.env.SERPAPI_KEY){
      const p=new URL('https://serpapi.com/search.json');p.searchParams.set('engine','google_maps');p.searchParams.set('q',b.keyword);p.searchParams.set('ll',`@${point.lat},${point.lng},14z`);p.searchParams.set('api_key',process.env.SERPAPI_KEY);
      result=await providerFetch({siteId,provider:'serpapi',operation:'local_grid',url:p.toString()});
    } else result=await serpSnapshot({siteId,keyword:b.keyword,location:b.location||'India',device:b.device||'mobile',engine:'google'});
    results.push({point,result});
   }
   const s=db();const {data,error}=await s.from('crm_seo_local_grid_runs').insert({site_id:siteId,keyword:b.keyword,center_lat:Number.isFinite(lat)?lat:null,center_lng:Number.isFinite(lng)?lng:null,radius_m:radius,grid_size:grid,device:b.device||'mobile',status:results.some(x=>x.result)?'completed':'provider_required',provider:process.env.SERPAPI_KEY?'serpapi':results[0]?.result?.provider||'none',results:{points:results},captured_at:new Date().toISOString()}).select('*').single();if(error)throw error;return NextResponse.json({ok:true,row:data,results});
  }
  if(action==='certify-layer'){
   const allowed=new Set(['not_started','foundation','implemented','verified','e2e_verified','production_certified']);
   const status=String(b.status||'verified');
   if(!allowed.has(status))throw new Error('Invalid certification status');
   if(status==='production_certified' && (!b.evidence?.build || !b.evidence?.e2e || !b.evidence?.runtime)) throw new Error('Production certification requires build, e2e and runtime evidence');
   const s=db(); const {data:current,error:ce}=await s.from('crm_seo_market_certification').select('*').eq('site_id',siteId).eq('version','2026.09.26-market-parity-v2').eq('category',b.category).eq('capability',b.capability).eq('layer',b.layer).maybeSingle(); if(ce)throw ce;
   if(!current)throw new Error('Certification item not found; initialize the current certification catalog first');
   const {data,error}=await s.from('crm_seo_market_certification').update({status,evidence:b.evidence||{},verified_at:new Date().toISOString()}).eq('id',current.id).select('*').single(); if(error)throw error; return NextResponse.json({ok:true,row:data});
  }
  return NextResponse.json({ok:false,error:'Unknown market-parity action'},{status:400});
 }catch(e){return NextResponse.json({ok:false,error:e.message},{status:e.status||500})}
}
