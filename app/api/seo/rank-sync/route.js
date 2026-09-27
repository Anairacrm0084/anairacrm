
import {db} from '../../../../lib/server/provider';import {requireSeoFeature} from '../../../../lib/server/seoRuntime';
export const runtime='nodejs';
function siteHost(domain){return new URL(domain.startsWith('http')?domain:`https://${domain}`).hostname.replace(/^www\./,'')}
function positionFor(results,host){for(let i=0;i<results.length;i++){const x=results[i];try{if(x.link&&new URL(x.link).hostname.replace(/^www\./,'')===host)return x.position||i+1}catch{}}return null}
export async function POST(req){
 try{
  const {siteId,country='IN',device='desktop',searchEngine='google',location,city,limit=200,gl='in',hl='en'}=await req.json();
  const {site}=await requireSeoFeature(req,siteId,'rank_tracking_enabled');if(!process.env.SERPAPI_KEY)throw new Error('SERPAPI_KEY is required for live rank collection');
  const s=db();const {data:keywords,error}=await s.from('crm_seo_keywords').select('*').eq('site_id',siteId).eq('active',true).limit(Math.min(1000,Number(limit)||200));if(error)throw error;
  const host=siteHost(site.domain);const rows=[];let synced=0;
  for(const k of keywords||[]){
    const qp=new URLSearchParams({engine:searchEngine,q:k.keyword,gl,country,hl,api_key:process.env.SERPAPI_KEY,num:'100',device});
    if(location||city)qp.set('location',location||city);
    const r=await fetch('https://serpapi.com/search.json?'+qp);const j=await r.json();if(!r.ok)throw new Error(j.error||'SERP provider error');
    const organic=j.organic_results||[],pos=positionFor(organic,host);
    const features=['answer_box','ai_overview','local_results','knowledge_graph','shopping_results','featured_snippet','top_stories','images_results','video_results','jobs_results','people_also_ask'].filter(x=>j[x]);
    await s.from('crm_seo_serp_snapshots').insert({site_id:siteId,keyword_id:k.id,keyword:k.keyword,search_engine:searchEngine,country,city:city||location||null,device,result_count:organic.length,results:organic.slice(0,100),features,captured_at:new Date().toISOString()});
    const visibility=pos?Math.max(0,Math.min(100,Math.round(100*(101-pos)/100))):0;
    rows.push({site_id:siteId,keyword_id:k.id,position:pos,url:pos?organic.find(x=>x.position===pos)?.link:null,search_engine:searchEngine,country,device,city:city||location||null,location:location||city||null,visibility,share_of_voice:null,rank_source:'serpapi',serp_features:features,source:'serpapi',created_at:new Date().toISOString()});
    synced++;
  }
  if(rows.length){
    const positions=rows.filter(x=>x.position!=null);const avg=positions.length?positions.reduce((a,x)=>a+x.position,0)/positions.length:null;
    const top10=positions.filter(x=>x.position<=10).length;
    const share=positions.length?top10/positions.length*100:0;
    const rankPayload=rows.map(r=>({...r,share_of_voice:share}));
    await s.from('crm_seo_rank_history').delete().eq('site_id',siteId).eq('created_at',rows[0]?.created_at||'1970-01-01T00:00:00.000Z').catch(()=>{});
    for(let i=0;i<rankPayload.length;i+=200){const {error}=await s.from('crm_seo_rank_history').insert(rankPayload.slice(i,i+200));if(error)throw error;}
    for(const r of rows)await s.from('crm_seo_keywords').update({previous_position:(keywords.find(k=>k.id===r.keyword_id)?.current_position??null),current_position:r.position,search_engine:searchEngine,country,device}).eq('id',r.keyword_id);
    return Response.json({ok:true,provider:'serpapi',synced,averagePosition:avg,top10Share:share,rows});
  }
  return Response.json({ok:true,provider:'serpapi',synced:0});
 }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
