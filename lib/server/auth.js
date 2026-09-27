import {db} from './provider';

export async function requireUser(req){
  const h=req.headers.get('authorization')||'';
  if(!h.startsWith('Bearer ')) throw new Error('Authentication required');
  const token=h.slice(7).trim();
  if(!token) throw new Error('Authentication required');
  // Server-side API authentication must use the server Supabase client.
  // Requiring NEXT_PUBLIC_* here made domain actions fail even when the server
  // service-role client was correctly configured.
  const c=db(token);
  const {data,error}=await c.auth.getUser(token);
  if(error||!data?.user) throw new Error('Invalid or expired session');
  return data.user;
}

function isTrustedCron(req){
  const cron=process.env.CRON_SECRET;
  const h=req?.headers?.get?.('authorization')||'';
  return Boolean(cron&&h===`Bearer ${cron}`);
}

export async function requireTenant(req,tenantId){
  const user=await requireUser(req);
  if(!tenantId) throw new Error('tenantId is required');
  const h=req.headers.get('authorization')||'';
  const token=h.startsWith('Bearer ')?h.slice(7).trim():null;
  const s=db(token);
  const {data:p,error}=await s.from('profiles').select('id,restaurant_id,is_super_admin,role,status').eq('id',user.id).maybeSingle();
  if(error) throw error;
  if(!p || (!p.is_super_admin && p.restaurant_id!==tenantId)) throw new Error('Tenant access denied');
  return {user,profile:p};
}

export async function requireSite(req,siteId){
  if(!siteId) throw new Error('siteId is required');
  const trustedCron=isTrustedCron(req);
  const s=db();
  const {data:site,error}=await s.from('crm_seo_sites').select('*').eq('id',siteId).single();
  if(error||!site) throw new Error('Site not found');
  if(!trustedCron) await requireTenant(req,site.tenant_id);
  return site;
}

async function effectiveSeoPermission(req,site,permissionKey){
  if(isTrustedCron(req)) return {user:null,profile:null,allowed:true};
  const user=await requireUser(req);
  const s=db();
  const {data:profile,error:pe}=await s.from('profiles').select('id,restaurant_id,is_super_admin,role,status').eq('id',user.id).maybeSingle();
  if(pe) throw pe;
  if(!profile || (!profile.is_super_admin && profile.restaurant_id!==site.tenant_id)) throw new Error('Tenant access denied');
  if(profile.is_super_admin) return {user,profile,allowed:true};

  const [roleQ,userQ,profileQ]=await Promise.all([
    s.from('anaira_role_permissions').select('permission_key').eq('role_key',profile.role||'staff').eq('permission_key',permissionKey).maybeSingle(),
    s.from('anaira_user_permissions').select('allowed').eq('user_id',user.id).eq('restaurant_id',site.tenant_id).eq('permission_key',permissionKey).maybeSingle(),
    s.from('anaira_user_profiles').select('profile_key').eq('user_id',user.id).eq('restaurant_id',site.tenant_id).maybeSingle()
  ]);
  if(roleQ.error) throw roleQ.error;
  if(userQ.error) throw userQ.error;
  if(profileQ.error) throw profileQ.error;

  let allowed=Boolean(roleQ.data);
  if(profileQ.data?.profile_key){
    const {data:pp,error}=await s.from('anaira_profile_permissions').select('permission_key').eq('profile_key',profileQ.data.profile_key).eq('permission_key',permissionKey).maybeSingle();
    if(error) throw error;
    if(pp) allowed=true;
  }
  if(userQ.data?.allowed!==undefined) allowed=userQ.data.allowed===true;
  if(!allowed) throw new Error(`SEO permission denied: ${permissionKey}`);
  return {user,profile,allowed:true};
}

export async function requireSeoPermission(req,siteId,permissionKey){
  const site=await requireSite(req,siteId);
  const access=await effectiveSeoPermission(req,site,permissionKey);
  return {site,...access};
}

export async function requireSeoPlatformConfigure(req,tenantId){
  if(isTrustedCron(req)) return {user:null,profile:null,allowed:true};
  if(!tenantId) throw new Error('tenantId is required');
  const user=await requireUser(req);
  const s=db();
  const {data:p,error}=await s.from('profiles').select('id,restaurant_id,is_super_admin,role,status').eq('id',user.id).maybeSingle();
  if(error) throw error;
  if(!p || (!p.is_super_admin && p.restaurant_id!==tenantId)) throw new Error('Tenant access denied');
  if(p.is_super_admin) return {user,profile:p,allowed:true};
  const permittedRoles=new Set(['admin']);
  if(!permittedRoles.has(String(p.role||'staff'))) throw new Error('SEO platform configuration requires admin permission');
  const {data:u,error:ue}=await s.from('anaira_user_permissions').select('allowed').eq('user_id',user.id).eq('restaurant_id',tenantId).eq('permission_key','seo-system.configure').maybeSingle();
  if(ue) throw ue;
  if(u?.allowed===false) throw new Error('SEO permission denied: seo-system.configure');
  const {data:r,error:re}=await s.from('anaira_role_permissions').select('permission_key').eq('role_key',p.role||'staff').eq('permission_key','seo-system.configure').maybeSingle();
  if(re) throw re;
  if(!r) throw new Error('SEO permission denied: seo-system.configure');
  return {user,profile:p,allowed:true};
}

export async function requireJobTenant(req,table,id,tenantColumn='tenant_id'){
  if(!id) throw new Error('id is required');
  const s=db();
  const {data:row,error}=await s.from(table).select('*').eq('id',id).single();
  if(error||!row) throw new Error('Record not found');
  let tenantId=row[tenantColumn];
  if(table.startsWith('crm_seo_') && tenantColumn==='site_id'){
    const {data:site,error:se}=await s.from('crm_seo_sites').select('tenant_id').eq('id',row.site_id).single();
    if(se||!site) throw new Error('SEO site not found');
    tenantId=site.tenant_id;
  }
  await requireTenant(req,tenantId);
  return row;
}

export function requireCron(req){
  const secret=process.env.CRON_SECRET;
  if(!secret) throw new Error('CRON_SECRET is not configured');
  const h=req.headers.get('authorization')||'';
  if(h!==`Bearer ${secret}`) throw new Error('Unauthorized cron request');
}
