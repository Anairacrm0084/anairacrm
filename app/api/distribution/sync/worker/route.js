import {NextResponse} from 'next/server';
import {db} from '../../../../../lib/server/provider';
import {requireCron} from '../../../../../lib/server/auth';
import {executeSync,parseCredentials} from '../../../../../lib/server/distribution/runtime';
export const runtime='nodejs';
export async function POST(req){
 try{requireCron(req);const s=db();const now=new Date().toISOString();
  const {data:jobs,error}=await s.from('ota_sync_events').select('*').eq('status','queued').lte('next_attempt_at',now).order('created_at').limit(20);if(error)throw error;
  let processed=0,failed=0;
  for(const job of jobs||[]){
   const attempt=Number(job.attempt_count||0)+1; await s.from('ota_sync_events').update({status:'processing',attempt_count:attempt,locked_at:now,locked_by:'distribution-worker'}).eq('id',job.id).eq('status','queued');
   try{
    let connection=null; if(job.connection_id){connection=(await s.from('anaira_distribution_connections').select('id,restaurant_id,platform_id,status,base_url,auth_type,credentials_ciphertext,credentials_ref,config,adapter_code').eq('id',job.connection_id).single()).data;} if(!connection && job.channel_id){const channel=(await s.from('ota_channels').select('platform_id,restaurant_id').eq('id',job.channel_id).single()).data; if(channel) connection=(await s.from('anaira_distribution_connections').select('id,restaurant_id,platform_id,status,base_url,auth_type,credentials_ciphertext,credentials_ref,config,adapter_code').eq('restaurant_id',channel.restaurant_id).eq('platform_id',channel.platform_id).maybeSingle()).data;}
    if(!connection||!['configured','connected'].includes(connection.status)) throw new Error('Distribution connection is not connected.');
    const platformId=connection.platform_id; const platform=(await s.from('anaira_distribution_platforms').select('*').eq('id',platformId).single()).data;
    if(!platform) throw new Error('Distribution platform not found.');
    const credentials=parseCredentials(connection); const result=await executeSync(connection,platform,credentials,job);
    await s.from('ota_sync_events').update({status:'success',processed_at:new Date().toISOString(),completed_at:new Date().toISOString(),last_error:null,response_payload:result,error_message:null}).eq('id',job.id);processed++;
   }catch(e){const max=Number(job.max_attempts||8);const dead=attempt>=max;const delay=Math.min(3600,Math.pow(2,Math.max(0,attempt-1))*30);await s.from('ota_sync_events').update({status:dead?'failed':'queued',error_message:e.message,last_error:e.message,next_attempt_at:new Date(Date.now()+delay*1000).toISOString(),locked_at:null,locked_by:null}).eq('id',job.id);failed++;}
  }
  return NextResponse.json({ok:true,processed,failed,count:(jobs||[]).length});
 }catch(e){return NextResponse.json({ok:false,error:e.message},{status:401})}
}
