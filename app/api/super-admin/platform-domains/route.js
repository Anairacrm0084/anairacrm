import {NextResponse} from 'next/server';
import {db,adminDb} from '../../../../lib/server/provider';

export const runtime='nodejs';
export const dynamic='force-dynamic';
const KEY='anaira_platform_hostnames';
const DEFAULT_HOSTS=['crm.anairapos.in','anaira.com','www.anaira.com'];
const clean=value=>String(value||'').trim().toLowerCase().replace(/^https?:\/\//,'').replace(/\/$/,'').replace(/:\d+$/,'').replace(/\.$/,'');
const valid=value=>/^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/.test(value);
const fail=(message,status=400)=>NextResponse.json({ok:false,error:message},{status});
async function actor(req){
 const h=req.headers.get('authorization')||'';if(!h.startsWith('Bearer '))throw Object.assign(new Error('Authentication required'),{status:401});
 const token=h.slice(7).trim(),client=db(token);const {data:{user},error}=await client.auth.getUser(token);
 if(error||!user)throw Object.assign(new Error('Invalid or expired session'),{status:401});
 const {data:profile,error:pe}=await client.from('profiles').select('id,role,is_super_admin').eq('id',user.id).maybeSingle();if(pe)throw pe;
 if(!profile?.is_super_admin&&profile?.role!=='super_admin')throw Object.assign(new Error('Super Admin access required'),{status:403});
 return {client:adminDb(),user};
}
export async function GET(req){try{const {client}=await actor(req);const {data,error}=await client.from('anaira_platform_settings').select('value').eq('key',KEY).maybeSingle();if(error)throw error;const saved=Array.isArray(data?.value?.value)?data.value.value:[];const hosts=[...new Set([...DEFAULT_HOSTS,...saved.map(clean).filter(x=>valid(x))])];return NextResponse.json({ok:true,hostnames:hosts,protected_hostnames:DEFAULT_HOSTS});}catch(e){return fail(e.message||'Unable to load platform domains',e.status||500)}}
export async function PUT(req){try{const {client,user}=await actor(req);const body=await req.json();const incoming=Array.isArray(body.hostnames)?body.hostnames:String(body.hostnames||'').split(/[\n,;]+/);const cleaned=[...new Set([...DEFAULT_HOSTS,...incoming.map(clean).filter(Boolean)])];const invalid=cleaned.filter(x=>!valid(x));if(invalid.length)return fail(`Invalid hostname: ${invalid.join(', ')}`);if(cleaned.length>100)return fail('Maximum 100 platform hostnames allowed');const {error}=await client.from('anaira_platform_settings').upsert({key:KEY,value:{value:cleaned},updated_by:user.id,updated_at:new Date().toISOString()},{onConflict:'key'});if(error)throw error;return NextResponse.json({ok:true,hostnames:cleaned,message:'Platform domain routing saved.'});}catch(e){return fail(e.message||'Unable to save platform domains',e.status||500)}}
