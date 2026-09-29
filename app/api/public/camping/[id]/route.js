import {NextResponse} from 'next/server';
import { supabase } from '../../../../../lib/supabase';
export const runtime='nodejs';
const json=(body,status=200)=>NextResponse.json(body,{status,headers:{'Cache-Control':'no-store'}});
export async function GET(req,{params}){
 try{
  const id=(await params).id;
  const [{data:camp,error:ce},{data:units,error:ue},{data:rates,error:re}]=await Promise.all([
   supabase.from('camp_properties').select('*').eq('restaurant_id',id).eq('active',true).eq('marketplace_visible',true).maybeSingle(),
   supabase.from('camp_unit_types').select('*').eq('restaurant_id',id).eq('active',true).order('name'),
   supabase.from('camp_rate_plans').select('*').eq('restaurant_id',id).eq('active',true).order('rate')
  ]);
  if(ce)throw ce;if(ue)throw ue;if(re)throw re;if(!camp)return json({ok:false,error:'Camping property not found.'},404);
  return json({ok:true,camp,units:(units||[]).map(u=>({...u,rates:(rates||[]).filter(r=>r.unit_type_id===u.id)}))});
 }catch(e){return json({ok:false,error:e?.message||'Camping property lookup failed.'},400)}
}
