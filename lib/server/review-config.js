import {db} from './provider';

const DEFAULTS={
  google_sync:true, review_requests:true, ai_classification:true, ai_reply_drafts:true,
  human_approval:true, auto_publish:false, service_recovery:true, sla_enabled:true,
  whatsapp_enabled:false, sms_enabled:false, email_enabled:false, request_delay_hours:24,
  default_recovery_hours:24, response_tone:'warm_professional', automation_enabled:true,
  template_fallback_enabled:true, push_notifications_enabled:false
};

export async function getReviewConfig(tenantId){
  const s=db();
  const {data:plugin,error:pe}=await s.from('restaurant_plugins').select('enabled,config').eq('restaurant_id',tenantId).eq('plugin_code','ai-review-system').maybeSingle();
  if(pe)throw pe;
  if(plugin && plugin.enabled===false)return null;
  const {data:ps,error}=await s.from('plugin_settings').select('config,custom_settings').eq('restaurant_id',tenantId).eq('plugin_code','ai-review-system').maybeSingle();
  if(error)throw error;
  return {...DEFAULTS,...(plugin?.config?.settings||{}),...(ps?.config?.settings||{}),...(ps?.custom_settings||{})};
}

export async function assertReviewPlugin(tenantId){
  const cfg=await getReviewConfig(tenantId);
  if(cfg===null)throw new Error('AI Review plugin is disabled for this property');
  return cfg;
}

export const REVIEW_DEFAULTS=DEFAULTS;
