import { createClient } from '@supabase/supabase-js';
export const runtime='nodejs';
export async function POST(){try{const u=process.env.NEXT_PUBLIC_SUPABASE_URL,k=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!u||!k)throw new Error('Server Supabase credentials are not configured.');const s=createClient(u,k,{auth:{persistSession:false,autoRefreshToken:false}});const {data,error}=await s.rpc('anaira_queue_prearrival_jobs');if(error)throw error;return Response.json({ok:true,queued:data});}catch(e){return Response.json({ok:false,error:e.message},{status:500});}}
