import {db,open,googleToken} from '../../../../lib/server/provider';
import {requireTenant,requireCron} from '../../../../lib/server/auth';
export const runtime='nodejs';

function ratingValue(x){return ({FIVE:5,FOUR:4,THREE:3,TWO:2,ONE:1})[x]||Number(x)||0}

async function syncSource(s,tenantId,src,int){
  const token=await googleToken(open(int.settings.refresh_token));
  const accountId=src.settings?.account_id||int.settings?.account_id;
  const locationId=src.location_id;
  if(!accountId||!locationId)throw new Error(`Google account/location mapping missing for source ${src.id}`);
  let pageToken=src.settings?.next_page_token||null,total=0,inserted=0,updated=0,pages=0;
  do{
    const u=new URL(`https://mybusiness.googleapis.com/v4/accounts/${accountId}/locations/${locationId}/reviews`);
    u.searchParams.set('pageSize','50'); if(pageToken)u.searchParams.set('pageToken',pageToken);
    const r=await fetch(u,{headers:{Authorization:`Bearer ${token}`}});
    const j=await r.json(); if(!r.ok)throw new Error(j.error?.message||'Google review sync failed');
    for(const rv of j.reviews||[]){
      const ext=rv.reviewId||rv.name; if(!ext)continue;
      const payload={tenant_id:tenantId,source:'google',external_review_id:ext,author_name:rv.reviewer?.displayName||null,rating:ratingValue(rv.starRating),review_text:rv.comment||'',reviewed_at:rv.createTime||new Date().toISOString(),language:null,sentiment:rv.comment?'pending':'neutral',status:'new',raw_payload:{...rv,locationId,accountId,locationName:`accounts/${accountId}/locations/${locationId}`}};
      const {data:existing}=await s.from('crm_reviews').select('id,reply_status,reply_text').eq('tenant_id',tenantId).eq('source','google').eq('external_review_id',ext).maybeSingle();
      if(existing){
        if(existing.reply_status==='published')continue;
        await s.from('crm_reviews').update({author_name:payload.author_name,rating:payload.rating,review_text:payload.review_text,reviewed_at:payload.reviewed_at,raw_payload:payload.raw_payload,status:'new',updated_at:new Date().toISOString()}).eq('id',existing.id); updated++;
      }else{const ins=await s.from('crm_reviews').insert(payload);if(ins.error)throw ins.error;inserted++;}
      total++;
    }
    pageToken=j.nextPageToken||null; pages++;
  }while(pageToken&&pages<20);
  await s.from('crm_review_provider_sync').upsert({tenant_id:tenantId,source_id:src.id,provider:'google',account_id:accountId,last_sync_at:new Date().toISOString(),next_sync_at:new Date(Date.now()+3600000).toISOString(),cursor:pageToken,status:'ok',attempts:0,last_error:null},{onConflict:'source_id'});
  return {sourceId:src.id,locationId,total,inserted,updated};
}

export async function POST(req){
  try{
    const {tenantId,sourceId}=await req.json(); await requireTenant(req,tenantId); const s=db();
    const {data:int}=await s.from('crm_seo_integrations').select('*').eq('tenant_id',tenantId).eq('provider','google_business_profile').maybeSingle();
    if(!int?.settings?.refresh_token)throw new Error('Connect Google Business Profile OAuth first');
    let q=s.from('crm_review_sources').select('*').eq('tenant_id',tenantId).eq('source','google').eq('active',true); if(sourceId)q=q.eq('id',sourceId);
    const {data:sources,error}=await q; if(error)throw error; if(!sources?.length)throw new Error('No Google review locations found. Click Discover Locations first.');
    const results=[];for(const src of sources){try{results.push(await syncSource(s,tenantId,src,int))}catch(e){results.push({sourceId:src.id,ok:false,error:e.message});}}
    return Response.json({ok:true,results});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}

export async function GET(req){
  try{requireCron(req);const s=db();const {data:rows}=await s.from('crm_review_sources').select('tenant_id,id').eq('source','google').eq('active',true).limit(500);const ids=[...new Set((rows||[]).map(x=>x.tenant_id).filter(Boolean))];const out=[];
    for(const tenantId of ids){const {data:int}=await s.from('crm_seo_integrations').select('*').eq('tenant_id',tenantId).eq('provider','google_business_profile').maybeSingle();if(!int?.settings?.refresh_token){out.push({tenantId,ok:false,error:'Google OAuth not connected'});continue;}const sources=(rows||[]).filter(x=>x.tenant_id===tenantId);for(const src of sources){try{out.push({tenantId,ok:true,...await syncSource(s,tenantId,src,int)})}catch(e){out.push({tenantId,sourceId:src.id,ok:false,error:e.message})}}}
    return Response.json({ok:true,results:out});
  }catch(e){return Response.json({ok:false,error:e.message},{status:401})}
}
