import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../lib/server/provider';
import {requireTenant} from '../../../../../lib/server/auth';
import {requireOtaProperty} from '../../../../../lib/server/distribution/property-guard';

export const runtime='nodejs';

export async function POST(req){
  try{
    const body=await req.json().catch(()=>({}));
    const restaurantId=String(body.restaurant_id||'').trim();
    const inboxId=String(body.inbox_id||'').trim();
    const action=String(body.action||'import');
    if(!restaurantId||!inboxId) throw Object.assign(new Error('Property and OTA inbox reservation are required.'),{status:400});
    if(!['import','modify','cancel'].includes(action)) throw Object.assign(new Error('Unsupported action.'),{status:400});
    await requireTenant(req,restaurantId);
    const s=adminDb();
    await requireOtaProperty(s,restaurantId);
    const {data,error}=await s.rpc('anaira_process_ota_reservation',{
      p_inbox_id:inboxId,
      p_restaurant_id:restaurantId,
      p_action:action
    });
    if(error) throw error;
    return NextResponse.json({ok:true,result:data});
  }catch(e){
    const status=Number(e?.status||(/Authentication|required|Invalid or expired session/i.test(e?.message||'')?401:(/Tenant access denied/i.test(e?.message||'')?403:400)));
    return NextResponse.json({ok:false,error:e?.message||'Unable to process OTA reservation.'},{status});
  }
}
