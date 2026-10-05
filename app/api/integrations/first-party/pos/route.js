import {NextResponse} from 'next/server';
import {db} from '../../../../../lib/server/provider';
import {requireTenant} from '../../../../../lib/server/auth';
export const runtime='nodejs';
export async function POST(req){
 try{
  const body=await req.json().catch(()=>({}));
  const tenantId=String(body.restaurant_id||'').trim();
  const {profile}=await requireTenant(req,tenantId);
  if(!profile?.is_super_admin && profile?.restaurant_id!==tenantId) throw new Error('Tenant access denied');
  const s=db();
  const {data:conn,error}=await s.from('anaira_integration_connections_v2').select('*').eq('restaurant_id',tenantId).eq('integration_type','pos').order('updated_at',{ascending:false}).limit(1).maybeSingle();
  if(error) throw error;
  if(!conn) throw new Error('Anaira POS integration is not configured for this property.');
  if(!conn.base_url) throw new Error('POS Base URL is not configured.');
  const cfg=conn.config||{}; const path=String(cfg.health_path||'/api/health'); const base=String(conn.base_url).replace(/\/$/,'');
  const started=Date.now(); const headers={'accept':'application/json'};
  if(conn.credentials_ref){const raw=process.env[String(conn.credentials_ref)];if(raw)headers.authorization=`Bearer ${raw}`;}
  const r=await fetch(`${base}${path}`,{headers,cache:'no-store'}); const text=await r.text(); let data={}; try{data=text?JSON.parse(text):{}}catch{data={raw:text};}
  if(!r.ok)throw new Error(data?.error||data?.message||`POS health check returned HTTP ${r.status}`);
  const latency=Date.now()-started;
  const {data:updated,error:ue}=await s.from('anaira_integration_connections_v2').update({status:'connected',last_sync_at:new Date().toISOString(),updated_at:new Date().toISOString(),config:{...cfg,last_health_status:'healthy',last_health_latency_ms:latency,last_health_at:new Date().toISOString()}}).eq('id',conn.id).select('*').single();
  if(ue)throw ue;
  return NextResponse.json({ok:true,health:'healthy',latency_ms:latency,data,connection:updated});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'POS health check failed'},{status:400})}
}
