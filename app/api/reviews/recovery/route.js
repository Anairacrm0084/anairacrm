import {db} from '../../../../lib/server/provider';
import {requireTenant} from '../../../../lib/server/auth';
import {ensureRecovery} from '../../../../lib/server/review-engine';

const ALLOWED={
  open:['in_progress','cancelled'],
  in_progress:['resolved','cancelled','open'],
  resolved:['reopened'],
  reopened:['in_progress','resolved','cancelled'],
  cancelled:['reopened']
};

export async function GET(req){
  try{
    const url=new URL(req.url); const tenantId=url.searchParams.get('tenantId');
    const actor=await requireTenant(req,tenantId); const s=db();
    const {data,error}=await s.from('crm_review_recovery_cases').select('*').eq('tenant_id',tenantId).order('created_at',{ascending:false}).limit(500);
    if(error)throw error; return Response.json({ok:true,cases:data||[]});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400});}
}

export async function POST(req){
  try{
    const body=await req.json(); const {tenantId,reviewId,ownerId,priority='high',dueHours=24,action='create',caseId}=body;
    const actor=await requireTenant(req,tenantId); const actorId=actor?.id||actor?.user?.id||null; const s=db();
    if(action==='create'){
      const {data:r,error:re}=await s.from('crm_reviews').select('*').eq('id',reviewId).eq('tenant_id',tenantId).single();
      if(re||!r)throw new Error('Review not found');
      const result=await ensureRecovery({tenantId,review:r,ownerId:ownerId||actorId,priority,dueHours,actorId});
      return Response.json({ok:true,...result});
    }
    if(!caseId)throw new Error('Recovery case ID is required');
    const {data:c,error:ce}=await s.from('crm_review_recovery_cases').select('*').eq('id',caseId).eq('tenant_id',tenantId).single();
    if(ce||!c)throw new Error('Recovery case not found');
    const target=String(action);
    const current=String(c.status||'open');
    let next=target;
    if(target==='assign') next='in_progress';
    if(target==='start') next='in_progress';
    if(target==='resolve') next='resolved';
    if(target==='reopen') next='reopened';
    if(target==='cancel') next='cancelled';
    if(!['in_progress','resolved','reopened','cancelled','open'].includes(next))throw new Error('Invalid recovery action');
    if(current!==next && !(ALLOWED[current]||[]).includes(next))throw new Error(`Cannot change recovery case from ${current} to ${next}`);
    const patch={status:next,updated_at:new Date().toISOString()};
    if(ownerId)patch.owner_id=ownerId;
    if(next==='resolved')patch.resolved_at=new Date().toISOString();
    if(next==='reopened')patch.resolved_at=null;
    const {data:updated,error:ue}=await s.from('crm_review_recovery_cases').update(patch).eq('id',caseId).eq('tenant_id',tenantId).select().single();
    if(ue)throw ue;
    await s.from('crm_review_recovery_events').insert({tenant_id:tenantId,recovery_case_id:caseId,event_type:target,actor_id:actorId,from_status:current,to_status:next,metadata:{owner_id:ownerId||c.owner_id||null}});
    return Response.json({ok:true,case:updated});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400});}
}
