import { requireTenant } from '../../../../lib/server/auth';
import { db } from '../../../../lib/server/provider';
import { syncHotelGuestTenant } from '../../../../lib/server/hotel-guest-sync';
export const runtime='nodejs';
export async function POST(req){
  try{
    const body=await req.json().catch(()=>({})); const tenantId=String(body.tenantId||'');
    const {user}=await requireTenant(req,tenantId); const s=db(req.headers.get('authorization')?.slice(7));
    const out={sync:null,analytics:false,prearrival:0,churn:0,segments:0};
    out.sync=await syncHotelGuestTenant(tenantId);
    const a=await s.rpc('anaira_refresh_crm_analytics',{p_tenant_id:tenantId,p_metric_date:new Date().toISOString().slice(0,10)}); out.analytics=!a.error;
    const q=await s.rpc('anaira_queue_prearrival_jobs',{p_tenant_id:tenantId}); if(q.error)throw q.error; out.prearrival=Number(q.data||0);
    const {data:customers}=await s.from('crm_customers').select('id,total_stays').eq('tenant_id',tenantId).limit(5000);
    for(const c of customers||[]){
      const {data:m}=await s.from('crm_restaurant_customer_metrics').select('last_visit_at,complaints_count').eq('tenant_id',tenantId).eq('customer_id',c.id).maybeSingle();
      const rec=m?.last_visit_at?Math.max(0,(Date.now()-new Date(m.last_visit_at).getTime())/86400000):180;
      const score=Math.max(0,Math.min(.99,Math.min(.55,rec/180*.55)+Math.min(.2,(Number(m?.complaints_count||0)/5)*.2)+(Number(c.total_stays||0)===0?.1:0)));
      await s.from('crm_churn_scores').upsert({tenant_id:tenantId,customer_id:c.id,score,risk_level:score>=.75?'high':score>=.5?'medium':'low',factors:[{key:'recency_days',value:Number(rec.toFixed(1))},{key:'complaints',value:Number(m?.complaints_count||0)},{key:'total_stays',value:Number(c.total_stays||0)}],calculated_at:new Date().toISOString()},{onConflict:'tenant_id,customer_id'}); out.churn++;
    }
    const {data:segments}=await s.from('crm_segments').select('id,definition').eq('tenant_id',tenantId).eq('active',true).limit(100);
    for(const seg of segments||[]){
      const d=typeof seg.definition==='string'?JSON.parse(seg.definition||'{}'):seg.definition||{};
      let q2=s.from('crm_customers').select('id,total_hotel_revenue,total_restaurant_revenue,total_restaurant_visits,vip,customer_type').eq('tenant_id',tenantId);
      if(d.customer_type)q2=q2.eq('customer_type',d.customer_type); if(d.vip!==undefined)q2=q2.eq('vip',!!d.vip);
      const {data:cs,error}=await q2.limit(5000);if(error)throw error;
      const matched=(cs||[]).filter(c=>d.min_ltv?(Number(c.total_hotel_revenue||0)+Number(c.total_restaurant_revenue||0)>=Number(d.min_ltv)):true).filter(c=>d.min_visits?Number(c.total_restaurant_visits||0)>=Number(d.min_visits):true);
      await s.from('crm_segment_members').delete().eq('segment_id',seg.id);if(matched.length)await s.from('crm_segment_members').insert(matched.map(c=>({segment_id:seg.id,customer_id:c.id,calculated_at:new Date().toISOString(),reason:'manual-worker'})));out.segments++;
    }
    await s.from('crm_audit_logs').insert({tenant_id:tenantId,actor_id:user.id,entity_type:'hotel_guest_crm',action:'manual_automation_run',after_data:out});
    return Response.json({ok:true,...out});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400});}
}
