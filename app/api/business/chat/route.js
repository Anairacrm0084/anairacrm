import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';

export async function POST(req){
  try{
    const b=await req.json(); const admin=supabaseAdmin();
    if(!b.business_id || !b.message) return NextResponse.json({error:'business_id and message are required'},{status:400});
    let conversation=null;
    if(b.conversation_id){
      const {data,error}=await admin.from('anaira_business_conversations').select('*').eq('id',b.conversation_id).eq('business_id',b.business_id).single();
      if(error) throw error; conversation=data;
    }else{
      const {data,error}=await admin.from('anaira_business_conversations').insert({
        business_id:b.business_id,customer_id:b.customer_id||null,customer_name:b.customer?.name||null,
        customer_email:b.customer?.email||null,customer_phone:b.customer?.phone||null,
        transaction_id:b.transaction_id||null,subject:b.subject||'Customer enquiry'
      }).select('*').single();
      if(error) throw error; conversation=data;
    }
    const {data:msg,error:me}=await admin.from('anaira_business_messages').insert({
      conversation_id:conversation.id,sender_type:b.sender_type==='staff'?'staff':'customer',
      sender_user_id:b.sender_user_id||null,body:String(b.message).slice(0,10000),attachments:Array.isArray(b.attachments)?b.attachments:[]
    }).select('*').single();
    if(me) throw me;
    return NextResponse.json({conversation,message:msg});
  }catch(e){return NextResponse.json({error:e.message||'Unable to send message'},{status:500});}
}
export async function GET(req){
  try{
    const u=new URL(req.url), id=u.searchParams.get('conversation_id');
    if(!id) return NextResponse.json({error:'conversation_id is required'},{status:400});
    const admin=supabaseAdmin();
    const {data:conversation,error}=await admin.from('anaira_business_conversations').select('*').eq('id',id).single();
    if(error) throw error;
    const {data:messages,error:me}=await admin.from('anaira_business_messages').select('*').eq('conversation_id',id).order('created_at');
    if(me) throw me;
    return NextResponse.json({conversation,messages:messages||[]});
  }catch(e){return NextResponse.json({error:e.message||'Unable to load conversation'},{status:500});}
}