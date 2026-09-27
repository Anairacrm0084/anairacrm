import crypto from 'node:crypto';

import {db,seal} from '../../../../../lib/server/provider';
function verifyState(state){const secret=process.env.ANAIRA_SECRET_KEY||process.env.ANAIRA_SECRET;if(!secret)throw new Error('ANAIRA_SECRET_KEY is required');const [body,sig]=String(state||'').split('.');const exp=crypto.createHmac('sha256',secret).update(body).digest('base64url');if(!body||!sig||!crypto.timingSafeEqual(Buffer.from(sig),Buffer.from(exp)))throw new Error('Invalid OAuth state');const data=JSON.parse(Buffer.from(body,'base64url').toString('utf8'));if(Date.now()-data.iat>10*60*1000)throw new Error('OAuth state expired');return data}
export async function GET(req){
 try{const u=new URL(req.url),code=u.searchParams.get('code'),state=u.searchParams.get('state');const {siteId}=verifyState(state);const {data:site,error:siteError}=await db().from('crm_seo_sites').select('*').eq('id',siteId).single();if(siteError||!site)throw new Error('Site unavailable');
  if(!code)throw new Error(u.searchParams.get('error_description')||u.searchParams.get('error')||'OAuth authorization failed');
  const redirect=`${process.env.NEXT_PUBLIC_APP_URL.replace(/\/$/,'')}/api/seo/local/callback`;
  const r=await fetch('https://oauth2.googleapis.com/token',{method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({client_id:process.env.GOOGLE_CLIENT_ID,client_secret:process.env.GOOGLE_CLIENT_SECRET,code,redirect_uri:redirect,grant_type:'authorization_code'})});
  const j=await r.json();if(!r.ok)throw new Error(j.error_description||'Google token exchange failed');
  const s=db();const {data:existing}=await s.from('crm_seo_integrations').select('settings').eq('tenant_id',site.tenant_id).eq('provider','google_business_profile').eq('property_id',siteId).maybeSingle();const refreshToken=j.refresh_token||existing?.settings?.refresh_token;if(!refreshToken)throw new Error('Google did not return a refresh token; reconnect with consent');const {error}=await s.from('crm_seo_integrations').upsert({tenant_id:site.tenant_id,provider:'google_business_profile',property_id:siteId,status:'connected',settings:{refresh_token:seal(refreshToken),scope:'https://www.googleapis.com/auth/business.manage'},last_sync_at:null,last_error:null},{onConflict:'tenant_id,provider,property_id'});
  if(error)throw error;return Response.redirect(`${process.env.NEXT_PUBLIC_APP_URL.replace(/\/$/,'')}/seo?siteId=${encodeURIComponent(siteId)}&local=connected`);
 }catch(e){return Response.redirect(`${process.env.NEXT_PUBLIC_APP_URL.replace(/\/$/,'')}/seo?local_error=${encodeURIComponent(e.message)}`)}
}
