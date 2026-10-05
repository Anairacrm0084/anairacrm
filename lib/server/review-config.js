import {db} from './provider';

export const REVIEW_BUSINESS_VERTICALS=[
  ['hotel','Hotel / Resort'],['restaurant','Restaurant / Dining'],['cafe','Cafe / Coffee Shop'],['bakery','Bakery / Patisserie'],
  ['bar','Bar / Lounge'],['catering','Catering'],['salon','Salon / Beauty Salon'],['barber','Barber Shop / Men’s Grooming'],['spa','Spa / Wellness'],
  ['clinic','Clinic / Healthcare'],['dentist','Dental Practice'],['doctor','Doctor / Medical Professional'],['hospital','Hospital'],['pharmacy','Pharmacy'],
  ['gym','Gym / Fitness'],['yoga','Yoga / Wellness Studio'],['retail','Retail Store'],['grocery','Grocery / Supermarket'],['fashion','Fashion / Apparel'],
  ['jewellery','Jewellery Store'],['electronics','Electronics / Mobile Store'],['furniture','Furniture / Home Store'],['automotive','Automotive / Car Dealer'],
  ['auto_service','Auto Service / Garage'],['real_estate','Real Estate / Property'],['travel','Travel Agency / Tour Operator'],['hotel_booking','Travel / Hotel Booking'],
  ['education','School / Education'],['coaching','Coaching / Training'],['legal','Law Firm / Legal Professional'],['accounting','Accounting / CA / Tax'],
  ['agency','Agency / Marketing / IT'],['professional_services','Professional Services'],['contractor','Contractor / Construction'],['home_services','Home Services'],
  ['pet_services','Pet Services / Veterinary'],['photography','Photography / Studio'],['events','Events / Banquet'],['entertainment','Entertainment / Recreation'],
  ['coworking','Coworking / Office'],['repair','Repair / Maintenance'],['cleaning','Cleaning Services'],['logistics','Courier / Logistics'],
  ['other','Other Local Business']
];

const DEFAULTS={
  google_sync:true, review_requests:true, ai_classification:true, ai_reply_drafts:true,
  human_approval:true, auto_publish:false, service_recovery:true, sla_enabled:true,
  whatsapp_enabled:false, sms_enabled:false, email_enabled:false, request_delay_hours:24,
  default_recovery_hours:24, response_tone:'warm_professional', automation_enabled:true,
  template_fallback_enabled:true, push_notifications_enabled:false
};

export function getReviewBusinessVerticals(){ return REVIEW_BUSINESS_VERTICALS.map(([value,label])=>({value,label})); }

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
