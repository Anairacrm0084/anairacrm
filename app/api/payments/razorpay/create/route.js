import { NextResponse } from 'next/server';
import { createRazorpayAdapter } from '../../../../../lib/integrations/razorpay';
import { supabaseAdmin } from '../../../../../lib/supabaseAdmin';

export async function POST(request){
  try{
    const body=await request.json();
    const {restaurant_id,reference_type,reference_id,amount,currency='INR',idempotency_key}=body||{};
    if(!restaurant_id||!reference_type||!reference_id||!Number(amount)||Number(amount)<=0) return NextResponse.json({error:'restaurant_id, reference_type, reference_id and positive amount are required'},{status:400});
    const key=process.env.RAZORPAY_KEY_ID, secret=process.env.RAZORPAY_KEY_SECRET;
    if(!key||!secret) return NextResponse.json({error:'Razorpay is not configured'},{status:503});
    const admin=supabaseAdmin();
    const {data:existing}=idempotency_key?await admin.from('anaira_payment_intents').select('*').eq('restaurant_id',restaurant_id).eq('idempotency_key',idempotency_key).maybeSingle():{data:null};
    if(existing) return NextResponse.json({payment:existing,reused:true});
    const adapter=createRazorpayAdapter({keyId:key,keySecret:secret});
    const order=await adapter.createPayment({amount:Number(amount),currency,receipt:`${reference_type}-${reference_id}`,notes:{reference_type,reference_id,restaurant_id}});
    if(!order?.id) return NextResponse.json({error:'Razorpay order creation failed',provider:order},{status:502});
    const {data:payment,error}=await admin.from('anaira_payment_intents').insert({restaurant_id,reference_type,reference_id,provider:'razorpay',amount:Number(amount),currency,status:'pending',idempotency_key,provider_order_id:order.id,metadata:{receipt:order.receipt||null}}).select('*').single();
    if(error) return NextResponse.json({error:error.message},{status:500});
    return NextResponse.json({payment,provider:{order_id:order.id,key_id:key,currency:order.currency,amount:order.amount}});
  }catch(e){return NextResponse.json({error:e.message||'Payment initialization failed'},{status:500})}
}
