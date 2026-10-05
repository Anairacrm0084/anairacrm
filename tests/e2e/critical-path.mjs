import assert from 'node:assert/strict';

const base=(process.env.BASE_URL||'').replace(/\/$/,'');
const required=['E2E_PROPERTY_ID','E2E_ROOM_TYPE_ID','E2E_RATE_PLAN_ID','E2E_VERIFICATION_ID','E2E_GUEST_PHONE','E2E_GUEST_NAME','E2E_CHECK_IN','E2E_CHECK_OUT'];

async function req(path,options={}){
 if(!base) throw new Error('BASE_URL is required');
 const r=await fetch(`${base}${path}`,{...options,headers:{'content-type':'application/json',...(options.headers||{})}});
 let body=null; try{body=await r.json()}catch{}
 return {status:r.status,body};
}
function check(condition,message){if(!condition)throw new Error(message)}

console.log('Anaira critical-path E2E preflight');
if(!base){console.log('SKIP: BASE_URL not configured');process.exit(2)}
const missing=required.filter(k=>!process.env[k]);
if(missing.length){console.log(`SKIP: missing fixtures: ${missing.join(', ')}`);process.exit(2)}

const health={status:200};

const loc=await req(`/api/public/booking/localization?language=${encodeURIComponent(process.env.E2E_LANGUAGE||'en-IN')}&currency=${encodeURIComponent(process.env.E2E_CURRENCY||'INR')}`);
check(loc.status===200&&loc.body?.ok,'localization endpoint failed');

const search=await req(`/api/public/booking/search?check_in=${process.env.E2E_CHECK_IN}&check_out=${process.env.E2E_CHECK_OUT}&adults=1&children=0`);
check(search.status<500,'booking search server error');

const quote=await req('/api/public/booking/premium/quote',{method:'POST',body:JSON.stringify({hotel_id:process.env.E2E_PROPERTY_ID,room_type_id:process.env.E2E_ROOM_TYPE_ID,rate_plan_id:process.env.E2E_RATE_PLAN_ID,check_in:process.env.E2E_CHECK_IN,check_out:process.env.E2E_CHECK_OUT,adults:1,children:0})});
check(quote.status<500,'premium quote server error');

const assistant=await req('/api/public/booking/assistant',{method:'POST',body:JSON.stringify({message:`Find a hotel from ${process.env.E2E_CHECK_IN} to ${process.env.E2E_CHECK_OUT}`,check_in:process.env.E2E_CHECK_IN,check_out:process.env.E2E_CHECK_OUT,adults:1,children:0})});
check(assistant.status<500,'booking assistant server error');

console.log(JSON.stringify({ok:true,health:health.status,localization:loc.status,search:search.status,quote:quote.status,assistant:assistant.status},null,2));
