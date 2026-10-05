import { createClient } from '@supabase/supabase-js';
import { requireCron, requireTenant } from '../../../../lib/server/auth';
import { db } from '../../../../lib/server/provider';
export const runtime='nodejs';
export async function POST(req){
  try{
    const body=await req.json().catch(()=>({}));
    const tenantId=String(body.tenantId||'');
    const auth=req.headers.get('authorization')||'';
    const isCron=process.env.CRON_SECRET && auth===`Bearer ${process.env.CRON_SECRET}`;
    if(isCron){
      const u=process.env.NEXT_PUBLIC_SUPABASE_URL,k=process.env.SUPABASE_SERVICE_ROLE_KEY;
      if(!u||!k)throw new Error('Server Supabase credentials are not configured.');
      const s=createClient(u,k,{auth:{persistSession:false,autoRefreshToken:false}});
      const {data,error}=await s.rpc('anaira_queue_prearrival_jobs');
      if(error)throw error;
      return Response.json({ok:true,queued:data,mode:'cron'});
    }
    if(!tenantId)throw new Error('tenantId is required');
    const {user}=await requireTenant(req,tenantId);
    const s=db(req.headers.get('authorization')?.slice(7));
    const {data,error}=await s.rpc('anaira_queue_prearrival_jobs');
    if(error)throw error;
    await s.from('crm_audit_logs').insert({tenant_id:tenantId,actor_id:user.id,entity_type:'prearrival_worker',action:'queue',after_data:{queued:data}});
    return Response.json({ok:true,queued:data,mode:'tenant'});
  }catch(e){return Response.json({ok:false,error:e.message},{status:401});}
}
