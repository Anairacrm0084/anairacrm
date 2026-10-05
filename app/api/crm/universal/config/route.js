import { NextResponse } from 'next/server';
import { db } from '../../../../../lib/server/provider';
import { requireTenant } from '../../../../../lib/server/auth';
import { CRM_BUSINESS_VERTICALS, CRM_INTERACTION_TYPES, buildCrmContext, normalizeCrmVertical } from '../../../../../lib/server/crm-universal';

export async function GET(req){
  try{
    const tenantId=new URL(req.url).searchParams.get('tenantId');
    await requireTenant(req,tenantId);
    const {data:profile,error}=await db().from('crm_business_profiles').select('*').eq('tenant_id',tenantId).maybeSingle();
    if(error)throw error;
    const vertical=normalizeCrmVertical(profile?.business_vertical);
    return NextResponse.json({ok:true,profile:profile||null,context:buildCrmContext({vertical,businessName:profile?.business_name,metadata:profile?.metadata}),business_verticals:CRM_BUSINESS_VERTICALS,interaction_types:CRM_INTERACTION_TYPES});
  }catch(e){return NextResponse.json({ok:false,error:e.message||'Unauthorized'},{status:/Authentication|Unauthorized|Tenant access/i.test(e.message||'')?401:400});}
}

export async function POST(req){
  try{
    const body=await req.json(); const tenantId=body.tenantId;
    await requireTenant(req,tenantId);
    const vertical=normalizeCrmVertical(body.businessVertical);
    const payload={tenant_id:tenantId,business_vertical:vertical,business_name:String(body.businessName||'').trim()||null,website_platform:String(body.websitePlatform||'').trim()||null,enabled:body.enabled!==false,metadata:body.metadata||{},updated_at:new Date().toISOString()};
    const {data,error}=await db().from('crm_business_profiles').upsert(payload,{onConflict:'tenant_id'}).select('*').single();
    if(error)throw error;
    return NextResponse.json({ok:true,profile:data,context:buildCrmContext({vertical,businessName:data.business_name,metadata:data.metadata})});
  }catch(e){return NextResponse.json({ok:false,error:e.message||'Unable to save CRM profile'},{status:/Authentication|Unauthorized|Tenant access/i.test(e.message||'')?401:400});}
}
