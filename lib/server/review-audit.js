import {db} from './provider';
export async function auditReview({tenantId,actorId,reviewId,action,status='success',before={},after={},metadata={}}){
  const s=db();
  await s.from('crm_audit_logs').insert({tenant_id:tenantId,actor_id:actorId||null,entity_type:'crm_review',entity_id:reviewId||null,action:`review.${action}.${status}`,before_data:before||null,after_data:{...after,...metadata},created_at:new Date().toISOString()}).catch(()=>{});
}
export async function providerAudit({tenantId,reviewId,provider,action,status,response={},error=null,actorId=null,idempotencyKey=null,expiresAt=null}){
  const s=db();
  await s.from('crm_review_provider_actions').insert({tenant_id:tenantId,review_id:reviewId||null,provider,action,status,response:response||{},error,actor_id:actorId,idempotency_key:idempotencyKey,google_content_expires_at:expiresAt||null}).catch(()=>{});
}
