import {db} from '../../../../lib/server/provider';
import {requireTenant} from '../../../../lib/server/auth';
import {ensureRecovery} from '../../../../lib/server/review-engine';
export async function POST(req){try{const {tenantId,reviewId,ownerId,priority='high',dueHours=24}=await req.json();const actor=await requireTenant(req,tenantId);const s=db();const {data:r,error:re}=await s.from('crm_reviews').select('*').eq('id',reviewId).eq('tenant_id',tenantId).single();if(re||!r)throw new Error('Review not found');const result=await ensureRecovery({tenantId,review:r,ownerId:ownerId||actor?.id||actor?.user?.id||null,priority,dueHours,actorId:actor?.id||actor?.user?.id||null});return Response.json({ok:true,...result});}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
