import {db} from '../../../../../lib/server/provider';

function fail(message,status=400){return new Response(JSON.stringify({ok:false,error:message}),{status,headers:{'Content-Type':'application/json'}})}

export async function POST(req){
  try{
    const h=req.headers.get('authorization')||'';
    if(!h.startsWith('Bearer '))return fail('Authentication required',401);
    const token=h.slice(7).trim();
    if(!token)return fail('Authentication required',401);
    const admin=db();
    const {data:{user},error:ue}=await admin.auth.getUser(token);
    if(ue||!user)return fail('Invalid or expired session',401);
    const {data:profile,error:pe}=await admin.from('profiles').select('id,role,is_super_admin').eq('id',user.id).maybeSingle();
    if(pe)throw pe;
    if(!profile?.is_super_admin && profile?.role!=='super_admin')return fail('Super Admin access required',403);

    const body=await req.json().catch(()=>({}));
    const propertyId=String(body.propertyId||'').trim();
    const confirmationEmail=String(body.confirmationEmail||'').trim().toLowerCase();
    if(!propertyId||!confirmationEmail)return fail('Property ID and confirmation email are required',400);

    const {data:property,error:propertyError}=await admin.from('restaurants').select('id,name,email,owner_id').eq('id',propertyId).maybeSingle();
    if(propertyError)throw propertyError;
    if(!property)return fail('Property not found',404);
    if(String(property.email||'').trim().toLowerCase()!==confirmationEmail)return fail('Confirmation email does not match this property',400);

    // Capture tenant users before deleting the restaurant. The profiles FK currently SET NULLs on tenant deletion.
    const {data:tenantProfiles,error:profilesError}=await admin.from('profiles').select('id,email,is_super_admin').eq('restaurant_id',propertyId);
    if(profilesError)throw profilesError;
    const userIds=[...new Set((tenantProfiles||[]).map(x=>x.id).filter(Boolean))];
    if(userIds.some(id=>id===user.id))return fail('You cannot delete the currently signed-in Super Admin account',400);
    if((tenantProfiles||[]).some(x=>x.is_super_admin===true))return fail('Safety stop: this property is linked to a Super Admin profile',400);

    // Never delete an Auth identity that is also attached to another business membership.
    if(userIds.length){
      const {data:otherMemberships,error:membershipError}=await admin.from('anaira_business_memberships').select('user_id,business_id').in('user_id',userIds).neq('business_id',propertyId);
      if(membershipError)throw membershipError;
      if((otherMemberships||[]).length)return fail('Safety stop: one or more tenant users are members of another business. Remove/reassign those memberships first.',409);
    }

    // Delete storage objects owned by tenant users first. This avoids Supabase Auth refusing user deletion
    // when a user still owns Storage objects.
    const storageDeleted=[];
    const storageWarnings=[];
    if(userIds.length){
      const {data:objects,error:storageQueryError}=await admin.from('storage.objects').select('bucket_id,name,owner_id').in('owner_id',userIds);
      if(storageQueryError)storageWarnings.push(storageQueryError.message);
      for(const obj of objects||[]){
        const r=await admin.storage.from(obj.bucket_id).remove([obj.name]);
        if(r.error)storageWarnings.push(`${obj.bucket_id}/${obj.name}: ${r.error.message}`); else storageDeleted.push(`${obj.bucket_id}/${obj.name}`);
      }
    }

    // restaurants has CASCADE FKs for the tenant data engine. The only non-cascade tenant FK is
    // profiles.restaurant_id (SET NULL), so all tenant records are removed atomically by this delete.
    const {error:deleteError}=await admin.from('restaurants').delete().eq('id',propertyId);
    if(deleteError)throw deleteError;

    const profileDelete=await admin.from('profiles').delete().in('id',userIds);
    if(profileDelete.error)throw profileDelete.error;

    const authFailures=[];
    for(const id of userIds){
      const r=await admin.auth.admin.deleteUser(id);
      if(r.error)authFailures.push({user_id:id,error:r.error.message});
    }

    if(authFailures.length)return new Response(JSON.stringify({ok:false,error:'PROPERTY_DATA_DELETED_AUTH_CLEANUP_INCOMPLETE',detail:'Property data was deleted, but one or more Auth accounts could not be removed.',authFailures,storageWarnings,property:{id:property.id,name:property.name,email:property.email}}),{status:500,headers:{'Content-Type':'application/json'}});
    return Response.json({ok:true,deleted:{propertyId:property.id,name:property.name,email:property.email,users:userIds.length,storageObjects:storageDeleted.length},storageWarnings});
  }catch(e){return fail(e?.message||'Property deletion failed',500)}
}
