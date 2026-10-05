import crypto from 'node:crypto';
import {db,seal,open} from '../provider';
import {NATIVE_PROVIDER_CODES,testNativeProvider,executeNativeSync} from './adapters/native.js';

export const STATUS={QUEUED:'queued',PROCESSING:'processing',SUCCESS:'success',FAILED:'failed'};
export const RETRYABLE=new Set([408,409,425,429,500,502,503,504]);

export function adapterCode(platform){
  const code=String(platform?.provider_code||'').toLowerCase();
  if(code==='anaira_booking_engine'||code==='anaira_marketplace') return 'anaira_internal';
  if(NATIVE_PROVIDER_CODES.has(code)) return `native_${code}`;
  if(code==='custom_api') return 'generic_rest';
  return code||'generic_rest';
}

export function parseCredentials(connection){
  if(connection.credentials_ciphertext){
    try{return JSON.parse(open(connection.credentials_ciphertext));}catch{throw new Error('Stored provider credentials could not be decrypted.');}
  }
  if(connection.credentials_ref){
    const ref=String(connection.credentials_ref).trim();
    const raw=process.env[ref];
    if(raw) return JSON.parse(raw);
  }
  return {};
}

function authHeaders(connection,credentials){
  const h={'content-type':'application/json','accept':'application/json'};
  const type=String(connection.auth_type||'api_key');
  if(type==='api_key' && credentials.api_key) h.authorization=`Bearer ${credentials.api_key}`;
  if(type==='basic' && credentials.username){h.authorization=`Basic ${Buffer.from(`${credentials.username}:${credentials.password||''}`).toString('base64')}`;}
  if(type==='oauth2' && credentials.access_token) h.authorization=`Bearer ${credentials.access_token}`;
  if(type==='hmac' && credentials.api_key) h['x-api-key']=credentials.api_key;
  if(credentials.headers && typeof credentials.headers==='object') Object.assign(h,credentials.headers);
  return h;
}

function urlFor(connection,path){
  const base=String(connection.base_url||'').replace(/\/$/,'');
  const p=String(path||'').startsWith('/')?String(path):`/${path||''}`;
  return `${base}${p}`;
}

async function request(connection,credentials,{path,method='GET',body,timeoutMs=20000}={}){
  if(!connection.base_url) throw new Error('Provider Base URL is not configured.');
  const ctrl=new AbortController(); const timer=setTimeout(()=>ctrl.abort(),timeoutMs);
  try{
    const response=await fetch(urlFor(connection,path),{method,headers:authHeaders(connection,credentials),body:body===undefined?undefined:JSON.stringify(body),signal:ctrl.signal,cache:'no-store'});
    const text=await response.text(); let data={}; try{data=text?JSON.parse(text):{}}catch{data={raw:text};}
    if(!response.ok){const e=new Error(data?.message||data?.error||`Provider HTTP ${response.status}`);e.status=response.status;throw e;}
    return {status:response.status,data};
  }finally{clearTimeout(timer)}
}

export async function testProvider(connection,platform,credentials){
  const started=Date.now();
  if(adapterCode(platform)==='anaira_internal') return {ok:true,status:'connected',latency_ms:Date.now()-started,adapter:'anaira_internal'};
  if(NATIVE_PROVIDER_CODES.has(String(platform?.provider_code||'').toLowerCase())) return testNativeProvider(connection,platform,credentials);
  const cfg=connection.config||{};
  const path=cfg.test_path||'/health';
  const result=await request(connection,credentials,{path,method:cfg.test_method||'GET',body:cfg.test_method&&cfg.test_method!=='GET'?cfg.test_body||{}:undefined});
  return {ok:true,status:'connected',latency_ms:Date.now()-started,http_status:result.status,adapter:adapterCode(platform)};
}

export async function executeSync(connection,platform,credentials,event){
  const code=adapterCode(platform);
  if(code==='anaira_internal') return {ok:true,provider_status:'accepted',adapter:code};
  if(NATIVE_PROVIDER_CODES.has(String(platform?.provider_code||'').toLowerCase())) return executeNativeSync(connection,platform,credentials,event);
  const cfg=connection.config||{};
  const path=event.event_type==='inventory'?(cfg.inventory_path||'/inventory'):
    event.event_type==='rates'?(cfg.rate_path||'/rates'):
    event.event_type==='reservation'?(cfg.reservation_path||'/reservations'):
    event.event_type==='availability'?(cfg.availability_path||'/availability'):
    (cfg.generic_path||'/sync');
  const method=event.event_type==='reservation'?(cfg.reservation_method||'POST'):(cfg.sync_method||'POST');
  const result=await request(connection,credentials,{path,method,body:event.payload||{}});
  return {ok:true,provider_status:'accepted',adapter:code,http_status:result.status,response:result.data};
}

export function idempotencyKey(parts){return crypto.createHash('sha256').update(parts.map(x=>String(x??'')).join('|')).digest('hex');}

export function encryptCredentials(value){return seal(JSON.stringify(value||{}));}
