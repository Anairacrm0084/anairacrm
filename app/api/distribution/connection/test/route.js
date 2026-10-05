import {NextResponse} from 'next/server';
import {encryptCredentials,testProvider} from '../../../../../lib/server/distribution/runtime';
import {db} from '../../../../../lib/server/provider';
import {open} from '../../../../../lib/server/provider';
import {requireTenant} from '../../../../../lib/server/auth';
export const runtime='nodejs';
export async function POST(req){
 try{
  const body=await req.json().catch(()=>({})); const tenantId=String(body.restaurant_id||body.tenantId||'');
  const {profile}=await requireTenant(req,tenantId); const s=db();
  if(!profile.is_super_admin && profile.restaurant_id!==tenantId) throw new Error('Tenant access denied');
  const {data:platform,error:pe}=await s.from('anaira_distribution_platforms').select('*').eq('id',body.platform_id).single(); if(pe) throw pe;
  if(!platform.active) throw new Error('Platform is disabled globally.');
  const {data:existing}=await s.from('anaira_distribution_connections').select('*').eq('restaurant_id',tenantId).eq('platform_id',platform.id).maybeSingle();
  let credentials=body.credentials||{};
  if(!Object.keys(credentials).length && existing?.credentials_ciphertext){
    try{credentials=JSON.parse(open(existing.credentials_ciphertext))}catch{}
  }
  if(!Object.keys(credentials).length && body.credentials_ref){const raw=process.env[String(body.credentials_ref).trim()];if(raw)try{credentials=JSON.parse(raw)}catch{}}
  const encrypted=Object.keys(credentials).length?encryptCredentials(credentials):(existing?.credentials_ciphertext||null);
  const payload={platform_id:platform.id,restaurant_id:tenantId,status:'not_configured',base_url:String(body.base_url||'').trim()||null,auth_type:body.auth_type||'api_key',credentials_ciphertext:encrypted,credentials_ref:String(body.credentials_ref||'').trim()||null,config:body.config||{},updated_at:new Date().toISOString(),last_error:null};
  const {data:connection,error:ce}=await s.from('anaira_distribution_connections').upsert(payload,{onConflict:'restaurant_id,platform_id'}).select('*').single(); if(ce) throw ce;
  try{
   const result=await testProvider(connection,platform,credentials);
   const {data:updated,error:ue}=await s.from('anaira_distribution_connections').update({status:'connected',connection_verified_at:new Date().toISOString(),test_latency_ms:result.latency_ms,last_error:null,adapter_code:result.adapter,updated_at:new Date().toISOString()}).eq('id',connection.id).select('*').single(); if(ue) throw ue;
   return NextResponse.json({ok:true,connection:updated,test:result});
  }catch(e){
   await s.from('anaira_distribution_connections').update({status:'error',last_error:e.message,test_latency_ms:null,updated_at:new Date().toISOString()}).eq('id',connection.id);
   return NextResponse.json({ok:false,error:e.message,status:'error'},{status:400});
  }
 }catch(e){return NextResponse.json({ok:false,error:e.message},{status:400})}
}
