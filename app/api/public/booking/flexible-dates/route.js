import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {adminDb} from '../../../../../lib/server/provider';

export const runtime='nodejs';

const TYPES=new Set(['hotel','camp','homestay','guest_house','cottage']);
const MAX_DAYS=31;
const MAX_NIGHTS=14;

function json(body,status=200){return NextResponse.json(body,{status,headers:{'Cache-Control':'no-store'}});}
function iso(d){return d.toISOString().slice(0,10);}
function parseDate(v){const d=new Date(`${v}T00:00:00Z`);return Number.isNaN(d.getTime())?null:d;}
function addDays(d,n){const x=new Date(d);x.setUTCDate(x.getUTCDate()+n);return x;}

async function search(db,q){
 const fn=q.hospitality_type==='camp'?'anaira_marketplace_camp_search':'anaira_marketplace_hms_hospitality_search';
 const args=q.hospitality_type==='camp'
  ? {p_check_in:q.check_in,p_check_out:q.check_out,p_adults:q.adults,p_children:q.children,p_destination:q.destination}
  : {p_hospitality_type:q.hospitality_type,p_check_in:q.check_in,p_check_out:q.check_out,p_adults:q.adults,p_children:q.children,p_destination:q.destination};
 const {data,error}=await db.rpc(fn,args); if(error) throw error;
 return Array.isArray(data)?data:[];
}

export async function GET(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:flexible-dates',limit:30,windowSeconds:60});
  const u=new URL(req.url);
  const from=parseDate(u.searchParams.get('from')||u.searchParams.get('check_in')||'');
  const nights=Math.min(MAX_NIGHTS,Math.max(1,Number(u.searchParams.get('nights')||2)));
  const days=Math.min(MAX_DAYS,Math.max(1,Number(u.searchParams.get('days')||14)));
  const adults=Math.max(1,Number(u.searchParams.get('adults')||2));
  const children=Math.max(0,Number(u.searchParams.get('children')||0));
  const destination=u.searchParams.get('destination')||null;
  const hospitality_type=TYPES.has(u.searchParams.get('hospitality_type'))?u.searchParams.get('hospitality_type'):'hotel';
  if(!from) return json({ok:false,error:'Valid from date is required.'},400);
  const db=adminDb();
  const dates=Array.from({length:days},(_,i)=>({check_in:iso(addDays(from,i)),check_out:iso(addDays(from,i+nights))}));
  const rows=await Promise.all(dates.map(async q=>{
   const results=await search(db,{...q,adults,children,destination,hospitality_type});
   const rates=results.map(x=>Number(x.rate??x.min_rate)).filter(Number.isFinite).filter(x=>x>=0);
   return {check_in:q.check_in,check_out:q.check_out,available:results.length>0,min_rate:rates.length?Math.min(...rates):null,result_count:results.length};
  }));
  const available=rows.filter(x=>x.available).sort((a,b)=>(a.min_rate??Infinity)-(b.min_rate??Infinity));
  return json({ok:true,query:{from:iso(from),days,nights,adults,children,destination,hospitality_type},calendar:rows,cheapest:available.slice(0,10)});
 }catch(e){return json({ok:false,error:e?.message||'Flexible-date search failed.'},400);}
}
