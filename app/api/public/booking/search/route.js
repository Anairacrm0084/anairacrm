import {NextResponse} from 'next/server';
import {supabase} from '../../../../../lib/supabase';

export const runtime='nodejs';

function cors(body,status=200){
 return NextResponse.json(body,{status,headers:{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Methods':'GET,OPTIONS','Access-Control-Allow-Headers':'Content-Type','Cache-Control':'no-store'}});
}
export async function OPTIONS(){return cors({ok:true});}

export async function GET(req){
 try{
  const u=new URL(req.url);
  const checkIn=u.searchParams.get('check_in');
  const checkOut=u.searchParams.get('check_out');
  const destination=u.searchParams.get('destination')||null;
  const adults=Math.max(1,Number(u.searchParams.get('adults')||2));
  const children=Math.max(0,Number(u.searchParams.get('children')||0));
  if(!checkIn||!checkOut||checkOut<=checkIn)return cors({ok:false,error:'Valid check-in and check-out dates are required.'},400);
  const {data,error}=await supabase.rpc('anaira_marketplace_hotel_search',{p_check_in:checkIn,p_check_out:checkOut,p_adults:adults,p_children:children,p_destination:destination});
  if(error)throw error;
  const rows=Array.isArray(data)?data:[];
  const ids=rows.map(x=>x.restaurant_id).filter(Boolean);
  let rates=[],settings=[];
  if(ids.length){
   const [r,s]=await Promise.all([
    supabase.from('hms_rate_plans').select('restaurant_id,room_type_id,name,code,rate,weekend_rate,board_type,active').in('restaurant_id',ids).eq('active',true).order('rate'),
    supabase.from('hms_settings').select('restaurant_id,star_rating,description,logo_url,cover_image_url,city,state,country,latitude,longitude').in('restaurant_id',ids)
   ]); if(r.error)throw r.error; if(s.error)throw s.error; rates=r.data||[]; settings=s.data||[];
  }
  const out=rows.map(x=>{
   const rr=rates.filter(r=>r.restaurant_id===x.restaurant_id);
   const hs=settings.find(s=>s.restaurant_id===x.restaurant_id)||{};
   const minRate=rr.length?Math.min(...rr.map(r=>Number(r.rate||Infinity))):null;
   return {...x,star_rating:hs.star_rating??null,description:hs.description||'',logo_url:hs.logo_url||x.logo||null,cover_image_url:hs.cover_image_url||x.cover_image||null,latitude:hs.latitude??null,longitude:hs.longitude??null,min_rate:Number.isFinite(minRate)?minRate:null,rate_count:rr.length};
  });
  return cors({ok:true,query:{check_in:checkIn,check_out:checkOut,destination,adults,children},results:out});
 }catch(e){return cors({ok:false,error:e?.message||'Search failed.'},400)}
}
