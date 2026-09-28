import {db} from '../../../../lib/server/provider';
import {requireTenant} from '../../../../lib/server/auth';
import {auditReview} from '../../../../lib/server/review-audit';
export async function POST(req){
  try{
    const {tenantId,reviewId,approved=true,reply}=await req.json();
    const access=await requireTenant(req,tenantId);
    const actorId=access?.user?.id||null;
    const s=db();
    const {data:r,error}=await s.from('crm_reviews').select('*').eq('id',reviewId).eq('tenant_id',tenantId).single();
    if(error||!r)throw new Error('Review not found');
    const nextStatus=approved?'approved':'rejected';
    const nextReply=reply||r.reply_text;
    const {error:ae}=await s.from('crm_review_ai_actions').update({status:nextStatus,approved_by:actorId,approved_at:new Date().toISOString(),draft_reply:nextReply}).eq('review_id',reviewId).eq('action_type','reply_draft').eq('status','pending_approval');
    if(ae)throw ae;
    const {error:re}=await s.from('crm_reviews').update({reply_text:nextReply,reply_status:nextStatus,updated_at:new Date().toISOString()}).eq('id',reviewId).eq('tenant_id',tenantId);
    if(re)throw re;
    await auditReview({tenantId,actorId,reviewId,action:approved?'approve_reply':'reject_reply',before:{reply_status:r.reply_status},after:{reply_status:nextStatus}});
    return Response.json({ok:true,status:nextStatus,actorId});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
