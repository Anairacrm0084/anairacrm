import { createClient } from '@supabase/supabase-js';
export const runtime='nodejs';
export async function POST(req){
 try{
  const form=await req.formData(); const file=form.get('file'); const restaurantId=String(form.get('restaurant_id')||'');
  if(!file||!restaurantId) return Response.json({ok:false,error:'file and restaurant_id are required'},{status:400});
  if(!String(file.type||'').startsWith('image/') && file.type!=='application/pdf') return Response.json({ok:false,error:'Only image or PDF receipts are allowed'},{status:400});
  if(file.size>8*1024*1024) return Response.json({ok:false,error:'Receipt must be 8MB or smaller'},{status:400});
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!url||!key) throw new Error('Server Supabase credentials are not configured.');
  const db=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
  const ext=(file.name.split('.').pop()||'bin').replace(/[^a-z0-9]/gi,'').toLowerCase()||'bin';
  const path=`hotel-payment-proofs/${restaurantId}/${crypto.randomUUID()}.${ext}`;
  const up=await db.storage.from('anaira-media').upload(path,file,{upsert:false,contentType:file.type||'application/octet-stream'});if(up.error)throw up.error;
  const pub=db.storage.from('anaira-media').getPublicUrl(path);return Response.json({ok:true,url:pub.data.publicUrl,path});
 }catch(e){return Response.json({ok:false,error:e.message},{status:500});}
}
