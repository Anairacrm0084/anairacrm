import crypto from 'node:crypto';
import {makeState} from '../../../../../lib/server/google';
import {requireTenant} from '../../../../../lib/server/auth';
export const runtime='nodejs';
async function build(req,tenantId,sourceId){
  const {user}=await requireTenant(req,tenantId);
  if(!process.env.GOOGLE_CLIENT_ID||!process.env.GOOGLE_CLIENT_SECRET)throw new Error('Google OAuth credentials are not configured on the server');
  const redirect=new URL('/api/reviews/source/callback',req.url).toString();
  const u=new URL('https://accounts.google.com/o/oauth2/v2/auth');
  u.searchParams.set('client_id',process.env.GOOGLE_CLIENT_ID);u.searchParams.set('redirect_uri',redirect);u.searchParams.set('response_type','code');
  u.searchParams.set('access_type','offline');u.searchParams.set('prompt','consent');u.searchParams.set('include_granted_scopes','true');u.searchParams.set('scope','https://www.googleapis.com/auth/business.manage');
  u.searchParams.set('state',makeState({provider:'google_business_profile',tenantId,sourceId:sourceId||null,userId:user.id,nonce:crypto.randomUUID(),issuedAt:Date.now()}));
  return u.toString();
}
export async function POST(req){try{const {tenantId,sourceId}=await req.json();const url=await build(req,tenantId,sourceId);return Response.json({ok:true,url})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
export async function GET(){return Response.json({ok:false,error:'Use POST with an authenticated CRM session to start Google OAuth'},{status:405})}
