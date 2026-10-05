const base=(process.env.BASE_URL||'').replace(/\/$/,'');
const a=process.env.E2E_TENANT_A_TOKEN,b=process.env.E2E_TENANT_B_TOKEN;
const tenantB=process.env.E2E_TENANT_B_ID;
if(!base||!a||!b||!tenantB){console.log('SKIP: BASE_URL, E2E_TENANT_A_TOKEN, E2E_TENANT_B_TOKEN and E2E_TENANT_B_ID are required');process.exit(2)}
async function get(path,token){const r=await fetch(`${base}${path}`,{headers:{authorization:`Bearer ${token}`}});return {status:r.status,text:await r.text()}}
const paths=[`/api/crm/customers?tenant_id=${encodeURIComponent(tenantB)}`,`/api/crm/analytics?tenant_id=${encodeURIComponent(tenantB)}`,`/api/hotel-guest-crm/guests?tenant_id=${encodeURIComponent(tenantB)}`];
const results=[];
for(const path of paths){const r=await get(path,a);results.push({path,status:r.status,denied:r.status===401||r.status===403||r.status===404})}
if(results.some(x=>!x.denied)) {console.error(JSON.stringify({ok:false,results},null,2));process.exit(1)}
console.log(JSON.stringify({ok:true,results},null,2));
