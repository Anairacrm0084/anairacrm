import {NextResponse} from 'next/server';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';

export async function POST(req){
 try{
  const b=await req.json();
  if(!b?.hotel_id)return NextResponse.json({ok:false,error:'hotel_id is required'},{status:400});
  const result={member:null,offers:[],corporate:null,negotiated:null,experiment:null};
  if(b.customer_id&&b.rate_plan_id){
   const {data,error}=await supabase.rpc('anaira_booking_member_context',{p_tenant_id:b.hotel_id,p_customer_id:b.customer_id,p_rate_plan_id:b.rate_plan_id,p_base_total:Number(b.base_total||0)});
   if(error)throw error; result.member=data;
  }
  const now=new Date().toISOString();
  const {data:offers,error:oe}=await supabase.from('booking_personalized_offers').select('*').eq('restaurant_id',b.hotel_id).eq('active',true)
    .or(`starts_at.is.null,starts_at.lte.${now}`).or(`ends_at.is.null,ends_at.gte.${now}`).order('priority',{ascending:true});
  if(oe)throw oe; result.offers=offers||[];
  if(b.corporate_code){
   const {data:c}=await supabase.from('booking_corporate_rates').select('*').eq('restaurant_id',b.hotel_id).eq('code',b.corporate_code).eq('active',true).maybeSingle();
   result.corporate=c||null;
  }
  if(b.negotiated_code){
   const {data:n}=await supabase.from('booking_negotiated_rates').select('*').eq('restaurant_id',b.hotel_id).eq('code',b.negotiated_code).eq('active',true).maybeSingle();
   result.negotiated=n||null;
  }
  if(b.experiment_key&&b.session_id){
   const {data:a,error:ae}=await supabase.rpc('anaira_booking_ab_assign',{p_restaurant_id:b.hotel_id,p_experiment_key:b.experiment_key,p_session_id:b.session_id});
   if(ae)throw ae; result.experiment=a;
  }
  return NextResponse.json({ok:true,...result});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Runtime context failed'},{status:400})}
}
