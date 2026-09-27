import crypto from 'node:crypto';
import { createClient } from '@supabase/supabase-js';

export const runtime = 'nodejs';

function client(){
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!url||!key) throw new Error('Server Supabase credentials are not configured.');
  return createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
}
function verifyHmac(raw,signature,secret){
  if(!secret||!signature) return false;
  const digest=crypto.createHmac('sha256',secret).update(raw).digest('hex');
  try{return crypto.timingSafeEqual(Buffer.from(digest),Buffer.from(signature));}catch{return false;}
}

export async function POST(req){
  try{
    const raw=await req.text();
    const provider=(req.headers.get('x-anaira-provider')||'generic').toLowerCase();
    const signature=req.headers.get('x-anaira-signature');
    const secret=process.env[`ANAIRA_${provider.toUpperCase()}_WEBHOOK_SECRET`]||process.env.ANAIRA_PAYMENT_WEBHOOK_SECRET;
    if(!verifyHmac(raw,signature,secret)) return Response.json({ok:false,error:'Invalid webhook signature'},{status:401});
    const body=JSON.parse(raw||'{}');
    const paymentIntentId=body.payment_intent_id||body.paymentIntentId||body.metadata?.payment_intent_id;
    const status=body.status||body.payment_status;
    if(!paymentIntentId||!status) return Response.json({ok:false,error:'payment_intent_id and status are required'},{status:400});
    const supabase=client();
    const {data,error}=await supabase.rpc('anaira_confirm_hotel_booking_payment',{p_payment_intent_id:paymentIntentId,p_provider:provider,p_provider_payment_id:body.provider_payment_id||body.payment_id||null,p_event_id:body.event_id||body.id||null,p_status:status,p_payload:body});
    if(error) return Response.json({ok:false,error:error.message},{status:400});
    return Response.json(data||{ok:true});
  }catch(e){return Response.json({ok:false,error:e.message},{status:500});}
}
