import crypto from 'node:crypto';
import {adminDb} from './provider';

export function clientKey(req, fallback='anonymous'){
  const forwarded=req?.headers?.get?.('x-forwarded-for')||req?.headers?.get?.('x-real-ip')||'';
  const ip=String(forwarded).split(',')[0].trim()||fallback;
  return ip;
}

export async function enforceRateLimit(req,{bucket='api',limit=60,windowSeconds=60,key}={}){
  const rawKey=String(key||clientKey(req));
  const keyHash=crypto.createHash('sha256').update(rawKey).digest('hex');
  const s=adminDb();
  const {data,error}=await s.rpc('anaira_rate_limit_check',{p_bucket:bucket,p_key_hash:keyHash,p_limit:limit,p_window_seconds:windowSeconds});
  if(error) throw error;
  const result=data&&typeof data==='object'?data:{};
  if(result.allowed===false){
    const e=new Error('Too many requests. Please try again later.');
    e.status=429;e.retryAfter=Number(result.retry_after||windowSeconds);throw e;
  }
  return result;
}
