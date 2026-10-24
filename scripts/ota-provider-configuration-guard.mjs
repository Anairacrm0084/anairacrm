import http from 'node:http';
import {testNativeProvider,executeNativeSync} from '../lib/server/distribution/adapters/native.js';

let requests=0;
const server=http.createServer((req,res)=>{requests++;res.writeHead(200,{'content-type':'application/json'});res.end(JSON.stringify({ok:true,path:req.url}));});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const port=server.address().port;
const platform={provider_code:'booking_com'};
const creds={api_key:'sandbox'};
let rejected=false;
try{await testNativeProvider({base_url:`http://127.0.0.1:${port}`,auth_type:'api_key',config:{}},platform,creds)}catch(e){rejected=/configure the Test Connection endpoint/i.test(e.message)}
if(!rejected)throw new Error('Missing provider test endpoint was not rejected.');
const connection={base_url:`http://127.0.0.1:${port}`,auth_type:'api_key',config:{test_path:'/provider-test',inventory_path:'/provider-inventory',rate_path:'/provider-rates',reservation_path:'/provider-reservations',availability_path:'/provider-availability'}};
const test=await testNativeProvider(connection,platform,creds);
const sync=await executeNativeSync(connection,platform,creds,{event_type:'inventory',payload:{quantity:2}});
server.close();
if(!test.ok||!sync.ok||test.provider_code!=='booking_com'||requests!==2)throw new Error('Configured provider transport check failed.');
console.log(JSON.stringify({status:'PASS',checks:3,missing_endpoint_rejected:true,configured_endpoint_tested:true,inventory_endpoint_tested:true,scope:'local mock transport only; not provider certification'},null,2));
