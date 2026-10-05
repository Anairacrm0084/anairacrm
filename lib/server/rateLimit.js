import {adminDb} from './provider.js';

function clientIp(req){
  const forwarded=req?.headers?.get('x-forwarded-for')||req?.headers?.get('x-real-ip')||'unknown';
  return String(forwarded).split(',')[0].trim().slice(0,128)||'unknown';
}

/** Distributed, DB-backed rate limiting. Fails closed when the limiter is unavailable. */
export async function enforceRateLimit(req,{scope,limit=60,windowSeconds=60,keyParts=[]}={}){
  const ip=clientIp(req);
  const key=[scope||'api',ip,...keyParts.map(x=>String(x??''))].join(':').slice(0,240);
  const db=adminDb();
  const {data,error}=await db.rpc('anaira_rate_limit_check',{p_key:key,p_limit:Math.max(1,Number(limit)),p_window_seconds:Math.max(1,Number(windowSeconds))});
  if(error) throw new Error(`Rate limiter unavailable: ${error.message}`);
  const row=Array.isArray(data)?data[0]:data;
  if(row && row.allowed===false){
    const retryAfter=Math.max(1,Number(row.retry_after_seconds||windowSeconds));
    const e=new Error('Too many requests. Please try again later.');
    e.status=429;e.retryAfter=retryAfter;
    throw e;
  }
  return {key,remaining:row?.remaining??null,retryAfter:row?.retry_after_seconds??null};
}

export function rateLimitResponse(e,NextResponse){
  const status=Number(e?.status||500);
  const headers={"Cache-Control":"no-store"};
  if(status===429) headers['Retry-After']=String(e.retryAfter||60);
  return NextResponse.json({ok:false,error:e?.message||'Request rejected.'},{status,headers});
}
