import {db,seal} from '../../../../../lib/server/provider';
import {readState,exchange} from '../../../../../lib/server/google';

export const runtime='nodejs';

export async function GET(req){
  try{
    const {searchParams}=new URL(req.url);
    const code=searchParams.get('code');
    const error=searchParams.get('error');
    if(error)throw new Error(`Google OAuth cancelled: ${error}`);
    const state=readState(searchParams.get('state'));
    if(!code)throw new Error('Google authorization code is missing');
    if(!state.tenantId||!state.userId)throw new Error('Invalid Google OAuth state');
    const t=await exchange(code,new URL('/api/reviews/source/callback',req.url).toString());
    const s=db();
    const {data:old}=await s.from('crm_seo_integrations').select('id,settings').eq('tenant_id',state.tenantId).eq('provider','google_business_profile').maybeSingle();
    const refresh=t.refresh_token||old?.settings?.refresh_token;
    if(!refresh)throw new Error('Google did not return a refresh token; reconnect with consent');
    const settings={...(old?.settings||{}),refresh_token:seal(refresh),scope:t.scope||old?.settings?.scope,connected_by:state.userId,connected_at:new Date().toISOString()};
    await s.from('crm_seo_integrations').upsert({tenant_id:state.tenantId,provider:'google_business_profile',property_id:state.sourceId||state.tenantId,settings,status:'connected',last_sync_at:null,last_error:null},{onConflict:'tenant_id,provider,property_id'});
    const target=new URL('/ai-reviews',req.url);target.searchParams.set('connected','google');return Response.redirect(target);
  }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
