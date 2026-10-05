import {NextResponse} from 'next/server';
import {db} from '../../../../lib/server/provider';
import {requireTenant} from '../../../../lib/server/auth';

export const runtime='nodejs';

export async function GET(req){
 try{
  const u=new URL(req.url);
  const tenantId=String(u.searchParams.get('restaurant_id')||u.searchParams.get('tenantId')||'');
  if(!tenantId) throw new Error('restaurant_id is required');
  const {profile}=await requireTenant(req,tenantId);
  if(!profile.is_super_admin && profile.restaurant_id!==tenantId) throw new Error('Tenant access denied');
  const s=db();
  const from=u.searchParams.get('from');
  const to=u.searchParams.get('to');
  let q=s.from('crm_channel_profitability').select('*').eq('tenant_id',tenantId).order('metric_date',{ascending:false}).limit(500);
  if(from) q=q.gte('metric_date',from);
  if(to) q=q.lte('metric_date',to);
  const {data,error}=await q; if(error) throw error;
  const rows=data||[];
  const totals=rows.reduce((a,r)=>{
   for(const k of ['gross_booking_value','ota_commission','payment_fee','tax_amount','refund_amount','discount_amount','net_revenue']) a[k]+=Number(r[k]||0);
   return a;
  },{gross_booking_value:0,ota_commission:0,payment_fee:0,tax_amount:0,refund_amount:0,discount_amount:0,net_revenue:0});
  totals.net_margin_percent=totals.gross_booking_value?Math.round(totals.net_revenue/totals.gross_booking_value*10000)/100:0;
  return NextResponse.json({ok:true,rows,totals});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Channel profitability failed'},{status:400});}
}
