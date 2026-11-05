import {NextResponse} from 'next/server';
import {encryptCredentials,testProvider} from '../../../../../lib/server/distribution/runtime';
import {db} from '../../../../../lib/server/provider';
import {open} from '../../../../../lib/server/provider';
import {requireTenant} from '../../../../../lib/server/auth';
import {requireOtaProperty} from '../../../../../lib/server/distribution/property-guard';
export const runtime='nodejs';
export async function POST(req){
 try{
  const body=await req.json().catch(()=>({})); const tenantId=String(body.restaurant_id||body.tenantId||'');
  const {profile}=await requireTenant(req,tenantId); const s=db();
  await requireOtaProperty(s,tenantId);
  if(!profile.is_super_admin && profile.restaurant_id!==tenantId) throw new Error('Tenant access denied');
  const platformQuery=s.from('anaira_distribution_platforms').select('*'); const {data:platform,error:pe}=body.platform_id?await platformQuery.eq('id',body.platform_id).single():await platformQuery.eq('provider_code',String(body.provider_code||'').toLowerCase()).single(); if(pe) throw pe;
  if(!platform.active) throw new Error('Platform is disabled globally.');
  const {data:existing}=await s.from('anaira_distribution_connections').select('*').eq('restaurant_id',tenantId).eq('platform_id',platform.id).maybeSingle();
  let credentials=body.credentials||{};
  if(!Object.keys(credentials).length && existing?.credentials_ciphertext){
    try{credentials=JSON.parse(open(existing.credentials_ciphertext))}catch{}
  }
  if(!Object.keys(credentials).length && body.credentials_ref){const raw=process.env[String(body.credentials_ref).trim()];if(raw)try{credentials=JSON.parse(raw)}catch{}}
  const encrypted=Object.keys(credentials).length?encryptCredentials(credentials):(existing?.credentials_ciphertext||null);
  const baseUrl=String(body.base_url||'').trim();
  if(!baseUrl) throw new Error('Provider Base URL is required.');
  let parsedUrl; try{parsedUrl=new URL(baseUrl)}catch{throw new Error('Provider Base URL must be a valid HTTPS URL.')}
  if(parsedUrl.protocol!=='https:' || parsedUrl.username || parsedUrl.password || ['localhost','127.0.0.1','::1'].includes(parsedUrl.hostname.toLowerCase()) || /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)/.test(parsedUrl.hostname)) throw new Error('Use the provider-approved public HTTPS API host. Local/private hosts are blocked.');
  const payload={platform_id:platform.id,restaurant_id:tenantId,status:existing?.status==='connected'?'configured':'not_configured',auto_sync:false,base_url:baseUrl,auth_type:body.auth_type||'api_key',credentials_ciphertext:encrypted,credentials_ref:String(body.credentials_ref||'').trim()||null,config:body.config||{},updated_at:new Date().toISOString(),last_error:null};
  const {data:connection,error:ce}=await s.from('anaira_distribution_connections').upsert(payload,{onConflict:'restaurant_id,platform_id'}).select('*').single(); if(ce) throw ce;
  try{
   const result=await testProvider(connection,platform,credentials);
   const {data:updated,error:ue}=await s.from('anaira_distribution_connections').update({status:'connected',connection_verified_at:new Date().toISOString(),test_latency_ms:result.latency_ms,last_error:null,adapter_code:result.adapter,updated_at:new Date().toISOString()}).eq('id',connection.id).select('*').single(); if(ue) throw ue;
   return NextResponse.json({ok:true,connection:{id:updated.id,platform_id:updated.platform_id,restaurant_id:updated.restaurant_id,status:updated.status,base_url:updated.base_url,auth_type:updated.auth_type,adapter_code:updated.adapter_code,connection_verified_at:updated.connection_verified_at,test_latency_ms:updated.test_latency_ms,auto_sync:updated.auto_sync,inventory_sync:updated.inventory_sync,rate_sync:updated.rate_sync,reservation_sync:updated.reservation_sync},test:result});
  }catch(e){
   await s.from('ota_channels').update({status:'error',auto_sync:false,settings:{...(existing?.settings||{}),setup_stage:'connection_test_failed',last_connection_error:e.message}}).eq('restaurant_id',tenantId).eq('platform_id',platform.id);
   await s.from('anaira_distribution_connections').update({status:'error',auto_sync:false,last_error:e.message,test_latency_ms:null,updated_at:new Date().toISOString()}).eq('id',connection.id);
   return NextResponse.json({ok:false,error:e.message,status:'error'},{status:400});
  }
 }catch(e){return NextResponse.json({ok:false,error:e.message},{status:400})}
}
