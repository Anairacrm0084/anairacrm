import http from 'node:http';
import {testNativeProvider,executeNativeSync} from '../lib/server/distribution/adapters/native.js';

const server=http.createServer((req,res)=>{let body='';req.on('data',c=>body+=c);req.on('end',()=>{res.writeHead(200,{'content-type':'application/json'});res.end(JSON.stringify({ok:true,path:req.url,event:body?JSON.parse(body):null}));});});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const port=server.address().port;
const connection={base_url:`http://127.0.0.1:${port}`,auth_type:'api_key',config:{test_path:'/health',inventory_path:'/inventory',sync_method:'POST'}};
const platform={provider_code:'booking_com'};
const credentials={api_key:'sandbox'};
const test=await testNativeProvider(connection,platform,credentials);
const sync=await executeNativeSync(connection,platform,credentials,{event_type:'inventory',payload:{room_type_id:'sandbox',availability:3}});
server.close();
if(!test.ok||!sync.ok||test.adapter!=='native_booking_com'||sync.adapter!=='native_booking_com') throw new Error('Provider sandbox E2E failed');
console.log(JSON.stringify({status:'PASS',provider:'booking_com',test_adapter:test.adapter,sync_adapter:sync.adapter},null,2));
