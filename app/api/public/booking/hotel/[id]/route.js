import {NextResponse} from 'next/server';
import {supabase} from '../../../../../../lib/supabase';
export const runtime='nodejs';
function cors(body,status=200){return NextResponse.json(body,{status,headers:{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Methods':'GET,OPTIONS','Access-Control-Allow-Headers':'Content-Type','Cache-Control':'no-store'}})}
export async function OPTIONS(){return cors({ok:true})}
export async function GET(req,{params}){
 try{
  const id=(await params).id;
  const [{data:h},{data:rooms,error:re},{data:rates,error:ra},{data:settings}]=await Promise.all([
   supabase.from('hms_settings').select('*').eq('restaurant_id',id).maybeSingle(),
   supabase.from('hms_room_types').select('*').eq('restaurant_id',id).eq('active',true).order('name'),
   supabase.from('hms_rate_plans').select('*').eq('restaurant_id',id).eq('active',true).order('rate'),
   supabase.from('booking_engine_settings').select('*').eq('restaurant_id',id).maybeSingle()
  ]);
  if(re)throw re;if(ra)throw ra;if(!h&&!rooms?.length)return cors({ok:false,error:'Hotel not found.'},404);
  const roomIds=(rooms||[]).map(x=>x.id);
  let inv=[];
  if(roomIds.length){const q=await supabase.from('hms_inventory').select('room_type_id,stay_date,total_rooms,sold_rooms,booked_rooms,held_rooms,blocked_rooms,closed').in('room_type_id',roomIds).order('stay_date');if(q.error)throw q.error;inv=q.data||[]}
  const payload={hotel:{id,name:h?.hotel_name||h?.short_name||'',...h},settings:settings||{},rooms:(rooms||[]).map(r=>({...r,rates:(rates||[]).filter(x=>x.room_type_id===r.id)})),inventory:inv};
  return cors({ok:true,...payload});
 }catch(e){return cors({ok:false,error:e?.message||'Hotel lookup failed.'},400)}
}
