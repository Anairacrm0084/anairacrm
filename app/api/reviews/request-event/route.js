import {db} from '../../../../lib/server/provider';
import {getReviewConfig, REVIEW_BUSINESS_VERTICALS} from '../../../../lib/server/review-config';
import {enforceRateLimit, rateLimitResponse} from '../../../../lib/server/rateLimit';

function validVertical(v){return REVIEW_BUSINESS_VERTICALS.some(([x])=>x===v)?v:'other';}
export async function POST(req){
  try{
    const body=await req.json();
    const tenantId=String(body.tenantId||'').trim(), customerId=String(body.customerId||'').trim();
    if(!tenantId||!customerId) return Response.json({ok:false,error:'tenantId and customerId are required'},{status:400});
    await enforceRateLimit(req,{scope:'review-request-event',limit:30,windowSeconds:3600,keyParts:[tenantId,customerId]});
    await getReviewConfig(tenantId);
    const vertical=validVertical(body.businessVertical);
    const s=db();
    const {data:source}=await s.from('crm_review_sources').select('id,review_url').eq('tenant_id',tenantId).eq('active',true).in('business_vertical',[vertical,'other']).order('created_at').limit(1).maybeSingle();
    if(!source?.review_url) return Response.json({ok:false,error:`No active review source configured for ${vertical}`},{status:409});
    const referenceType=String(body.referenceType||'customer_interaction'), referenceId=String(body.referenceId||'');
    if(!referenceId)return Response.json({ok:false,error:'referenceId is required'},{status:400});
    const {data:event,error}=await s.from('crm_review_request_events').upsert({tenant_id:tenantId,customer_id:customerId,reference_type:referenceType,reference_id:referenceId,business_vertical:vertical,completed_at:body.completedAt||new Date().toISOString(),delay_hours:Number(body.delayHours??24),status:'eligible',metadata:body.metadata&&typeof body.metadata==='object'?body.metadata:{},created_at:new Date().toISOString()},{onConflict:'id'}).select().single();
    if(error)throw error;
    return Response.json({ok:true,event,reviewUrl:source.review_url});
  }catch(e){return rateLimitResponse(e,Response);}
}
