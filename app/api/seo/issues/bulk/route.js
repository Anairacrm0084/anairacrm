import {db} from '../../../../../lib/server/provider';
import {requireSeoUser} from '../../../../../lib/server/seoRuntime';

export async function POST(req){
  try{
    const {siteId,ids=[],action,assigned_to,ignored_until}=await req.json();
    const {user}=await requireSeoUser(req,siteId,'technical_issues');
    if(!Array.isArray(ids)||!ids.length) throw new Error('ids are required');
    if(!['resolve','open','in_progress','ignore','snooze','assign'].includes(action)) throw new Error('Unsupported bulk issue action');
    const s=db();
    const {data:before,error:be}=await s.from('crm_seo_issues').select('*').eq('site_id',siteId).in('id',ids);
    if(be)throw be;
    const patch={last_seen_at:new Date().toISOString()};
    if(action==='resolve'){patch.status='resolved';patch.resolved_at=new Date().toISOString()}
    if(action==='open'||action==='in_progress'){patch.status=action;patch.resolved_at=null}
    if(action==='ignore'){patch.status='ignored'}
    if(action==='snooze'){patch.ignored_until=ignored_until||new Date(Date.now()+86400000).toISOString();patch.status='ignored'}
    if(action==='assign'){patch.assigned_to=assigned_to||null}
    const {data,error}=await s.from('crm_seo_issues').update(patch).eq('site_id',siteId).in('id',ids).select();
    if(error)throw error;
    const rows=(data||[]).map(x=>({site_id:siteId,issue_id:x.id,action,before_data:(before||[]).find(b=>b.id===x.id)||{},after_data:x,actor_id:user.id}));
    if(rows.length){const {error:he}=await s.from('crm_seo_issue_history').insert(rows);if(he)throw he}
    return Response.json({ok:true,count:data?.length||0,issues:data||[]});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
