
import crypto from 'node:crypto';
import {db,seal,open,googleToken} from '../../../../../lib/server/provider';
import {requireSeoFeature} from '../../../../../lib/server/seoRuntime';
const scope='https://www.googleapis.com/auth/business.manage';
function signState(siteId){
 const secret=process.env.ANAIRA_SECRET_KEY||process.env.ANAIRA_SECRET;if(!secret)throw new Error('ANAIRA_SECRET_KEY is required');
 const body=Buffer.from(JSON.stringify({siteId,iat:Date.now()})).toString('base64url');
 const sig=crypto.createHmac('sha256',secret).update(body).digest('base64url');return `${body}.${sig}`;
}
function verifyState(state){
 const secret=process.env.ANAIRA_SECRET_KEY||process.env.ANAIRA_SECRET;if(!secret)throw new Error('ANAIRA_SECRET_KEY is required');
 const [body,sig]=String(state||'').split('.');const exp=crypto.createHmac('sha256',secret).update(body).digest('base64url');
 if(!body||!sig||!crypto.timingSafeEqual(Buffer.from(sig),Buffer.from(exp)))throw new Error('Invalid OAuth state');
 const data=JSON.parse(Buffer.from(body,'base64url').toString('utf8'));if(Date.now()-data.iat>10*60*1000)throw new Error('OAuth state expired');return data;
}
export async function GET(req){
 try{
  const u=new URL(req.url),siteId=u.searchParams.get('siteId');await requireSeoFeature(req,siteId,'local_seo_enabled','seo-system.manage');
  if(!process.env.GOOGLE_CLIENT_ID||!process.env.GOOGLE_CLIENT_SECRET||!process.env.NEXT_PUBLIC_APP_URL)throw new Error('GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET and NEXT_PUBLIC_APP_URL are required');
  const redirect=`${process.env.NEXT_PUBLIC_APP_URL.replace(/\/$/,'')}/api/seo/local/callback`;
  const auth=new URL('https://accounts.google.com/o/oauth2/v2/auth');auth.searchParams.set('client_id',process.env.GOOGLE_CLIENT_ID);auth.searchParams.set('redirect_uri',redirect);auth.searchParams.set('response_type','code');auth.searchParams.set('access_type','offline');auth.searchParams.set('prompt','consent');auth.searchParams.set('scope',scope);auth.searchParams.set('state',signState(siteId));return Response.json({ok:true,url:auth.toString()});
 }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
