import { db } from '../../../../lib/server/provider';
import { requireTenant } from '../../../../lib/server/auth';
import { syncHotelGuestTenant } from '../../../../lib/server/hotel-guest-sync';
export const runtime='nodejs';
export async function POST(req){try{const body=await req.json().catch(()=>({}));const tenantId=String(body.tenantId||'');const actor=await requireTenant(req,tenantId);const result=await syncHotelGuestTenant(tenantId);await db().from('crm_audit_logs').insert({tenant_id:tenantId,actor_id:actor?.id||actor?.user?.id||null,entity_type:'hotel_guest_crm',entity_id:null,action:'source_sync',after_data:result});return Response.json({ok:true,...result});}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
