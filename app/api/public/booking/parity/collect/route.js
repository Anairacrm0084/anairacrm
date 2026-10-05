import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../../lib/server/provider';
import {requestWithConnection} from '../../../../../../lib/server/distribution/runtime-core';
import {open} from '../../../../../../lib/server/provider';
export const runtime='nodejs';
export async function POST(req){
 try{
  const b=await req.json(); if(!b?.hotel_id||!b?.stay_date)return NextResponse.json({ok:false,error:'hotel_id and stay_date are required'},{status:400});
  const {data:sources,error:se}=await adminDb().from('booking_competitor_rate_sources').select('*').eq('restaurant_id',b.hotel_id).eq('active',true); if(se)throw se;
  const rows=[];
  for(const source of sources||[]){
   const cfg=source.config||{}; const credentials=source.credentials_ciphertext?JSON.parse(open(source.credentials_ciphertext)):{};
   if(!source.base_url)continue;
   const result=await requestWithConnection({base_url:source.base_url,auth_type:cfg.auth_type||'api_key'},credentials,{path:cfg.rate_path||'/rates',method:cfg.method||'POST',body:{hotel_id:b.hotel_id,stay_date:b.stay_date,check_in:b.check_in||b.stay_date,check_out:b.check_out||b.stay_date,guests:b.guests||2}});
   const items=Array.isArray(result.data)?result.data:(Array.isArray(result.data?.rates)?result.data.rates:[]);
   for(const x of items){if(x?.rate==null)continue;rows.push({restaurant_id:b.hotel_id,source_code:source.source_code,property_name:x.property_name||x.hotel_name||source.source_name,room_name:x.room_name||x.room_type||null,stay_date:b.stay_date,rate:Number(x.rate),currency:x.currency||'INR',refundable:x.refundable!==false,raw:x,collected_at:new Date().toISOString(),expires_at:new Date(Date.now()+Number(cfg.ttl_minutes||30)*60000).toISOString()});}
  }
  if(rows.length){const {error}=await adminDb().from('booking_competitor_rates').insert(rows);if(error)throw error;}
  return NextResponse.json({ok:true,collected:rows.length,sources:(sources||[]).length});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Competitor collection failed'},{status:400})}
}
