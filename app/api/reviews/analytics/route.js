import {db} from '../../../../lib/server/provider';
import {requireTenant} from '../../../../lib/server/auth';
export const runtime='nodejs';
export async function GET(req){
 try{
  const {searchParams}=new URL(req.url);const tenantId=searchParams.get('tenantId');await requireTenant(req,tenantId);const s=db();
  const [{data:reviews,error},{data:recovery},{data:reqs}]=await Promise.all([
   s.from('crm_reviews').select('source,rating,sentiment,reviewed_at,reply_status,replied_at').eq('tenant_id',tenantId).order('reviewed_at',{ascending:false}).limit(10000),
   s.from('crm_review_recovery_cases').select('status,due_at,resolved_at').eq('tenant_id',tenantId).limit(5000),
   s.from('crm_review_request_jobs').select('status,created_at,sent_at').eq('tenant_id',tenantId).limit(5000)
  ]);if(error)throw error;
  const rows=reviews||[];const avg=rows.length?rows.reduce((a,x)=>a+Number(x.rating||0),0)/rows.length:0;const positive=rows.filter(x=>x.sentiment==='positive').length,negative=rows.filter(x=>x.sentiment==='negative'||Number(x.rating)<=2).length,neutral=rows.length-positive-negative;const replied=rows.filter(x=>x.reply_status==='published'&&x.replied_at);
  const responseHours=replied.length?replied.map(x=>Math.max(0,(new Date(x.replied_at)-new Date(x.reviewed_at))/3600000)).reduce((a,x)=>a+x,0)/replied.length:0;
  const bySource={};for(const x of rows){const k=x.source||'unknown';const b=bySource[k]||{total:0,rating:0,negative:0};b.total++;b.rating+=Number(x.rating||0);if(x.sentiment==='negative'||Number(x.rating)<=2)b.negative++;bySource[k]=b;}for(const k of Object.keys(bySource))bySource[k]={...bySource[k],avgRating:Number((bySource[k].rating/bySource[k].total).toFixed(2))};
  const days=new Map();for(const x of rows){const d=(x.reviewed_at||'').slice(0,10);if(!d)continue;const b=days.get(d)||{date:d,total:0,rating:0,positive:0,negative:0};b.total++;b.rating+=Number(x.rating||0);if(x.sentiment==='positive')b.positive++;if(x.sentiment==='negative'||Number(x.rating)<=2)b.negative++;days.set(d,b);}const dailyTrend=[...days.values()].sort((a,b)=>a.date.localeCompare(b.date)).slice(-30).map(x=>({...x,avgRating:Number((x.rating/x.total).toFixed(2))}));
  const open=(recovery||[]).filter(x=>['open','in_progress'].includes(x.status)).length,resolved=(recovery||[]).filter(x=>x.status==='resolved').length,overdue=(recovery||[]).filter(x=>['open','in_progress'].includes(x.status)&&x.due_at&&new Date(x.due_at)<new Date()).length;
  const requests=reqs||[];const sentRequests=requests.filter(x=>x.status==='sent').length;const recoveryRate=(open+resolved)?Number((resolved/(open+resolved)*100).toFixed(1)):0;
  return Response.json({ok:true,total:rows.length,avgRating:Number(avg.toFixed(2)),positive,negative,neutral,responseRate:rows.length?Number((replied.length/rows.length*100).toFixed(1)):0,avgResponseHours:Number(responseHours.toFixed(1)),bySource,dailyTrend,recovery:{open,resolved,overdue,rate:recoveryRate},reviewRequests:{total:requests.length,sent:sentRequests}});
 }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
