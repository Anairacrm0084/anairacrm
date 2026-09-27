import {db} from './provider';
import {requireSite,requireUser,requireSeoPermission,requireSeoPlatformConfigure} from './auth';

export const DEFAULTS={
  sitemap_enabled:true,robots_enabled:true,respect_robots:true,scheduled_crawl:true,crawl_max_pages:500,
  browser_rendering:false,gsc_enabled:true,ga4_enabled:true,rank_tracking_enabled:true,
  ai_content_enabled:true,internal_links_enabled:true,schema_enabled:true,redirects_enabled:true,technical_issues:true,
  backlinks_enabled:true,local_seo_enabled:true,geo_visibility_enabled:true,competitor_intelligence_enabled:true,
  reports_enabled:true,keyword_research_enabled:true
};

export async function loadSeoSettings(site){
  const {data}=await db().from('plugin_settings').select('config').eq('restaurant_id',site.tenant_id).eq('plugin_code','seo-system').maybeSingle();
  return {...DEFAULTS,...(data?.config?.settings||data?.config||{})};
}

function permissionFor(req){
  const method=req?.method?.toUpperCase?.()||'GET';
  return method==='GET'||method==='HEAD'?'seo-system.view':'seo-system.manage';
}

export async function requireSeoFeature(req,siteId,key,permission){
  const site=await requireSite(req,siteId);
  const settings=await loadSeoSettings(site);
  if(key && settings[key]===false) throw new Error(`SEO feature disabled: ${key}`);
  await requireSeoPermission(req,siteId,permission||permissionFor(req));
  return {site,settings};
}

export async function requireSeoUser(req,siteId,key){
  const {site,settings}=await requireSeoFeature(req,siteId,key,'seo-system.manage');
  const user=await requireUser(req);
  return {site,settings,user};
}

export {requireSeoPermission,requireSeoPlatformConfigure};

export async function recordProvider(siteId,provider,status,meta={}){
  const s=db();
  const {error}=await s.from('crm_seo_provider_health').upsert({
    site_id:siteId,provider,status,checked_at:new Date().toISOString(),
    latency_ms:meta.latencyMs??null,last_error:meta.error??null,metadata:meta,
  },{onConflict:'site_id,provider'});
  if(error) throw error;
}
export const csvEscape=v=>`"${String(v??'').replace(/"/g,'""')}"`;
