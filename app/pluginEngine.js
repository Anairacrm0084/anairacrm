import {pluginRegistry} from './pluginRegistry';
import {getEnhancedSettings} from './pluginSettingExtensions';

const primaryKeys={
  restaurant_crm:['tenant_id','customer_id'],
  advanced_analytics:['tenant_id','metric_date']
};

const tenantColumns={
  'hotel-management-suite':'restaurant_id','hotel-pms':'restaurant_id','restaurant-reservation':'restaurant_id','food-delivery':'restaurant_id','restaurant-store':'restaurant_id','anaira-pos':'restaurant_id','channel-manager':'restaurant_id'
};

const stringStatusFields={
  crm:null,'hotel-booking':'state','hotel-management-suite':'status','hotel-pms':'status','restaurant-reservation':'status','food-delivery':'status','restaurant-store':'status','anaira-pos':'status','channel-manager':'status','seo-system':null,'ai-review-system':'status',customer_360:null,customer_intelligence:null,hotel_guest_crm:'booking_status',restaurant_crm:null,customer_ltv:null,lead_management:'stage',followups:'status',corporate_crm:null,partner_crm:null,loyalty:null,offers_coupons:null,marketing_automation:'status',whatsapp_crm:'status',reputation:'reply_status',guest_relations:'status',segmentation:null,churn:'risk_level',vip:null,revenue_management:'status',upselling:null,cross_selling:null,event_crm:'stage',omnichannel_timeline:null,consent_privacy:'status',relationship_manager:null,advanced_analytics:null,ai_crm:null,revenue_forecasting:null,competitor_intelligence:null
};

const domainActions={
  crm:[['refresh_value','Refresh Customer Value','derive'],['open_360','Open Customer 360','navigate']],
  customer_360:[['refresh_timeline','Refresh Timeline','derive'],['refresh_value','Refresh Value','derive']],
  customer_intelligence:[['refresh_insights','Refresh Insights','derive'],['recompute_scores','Recompute Scores','derive']],
  hotel_guest_crm:[['prearrival_check','Pre-arrival Check','derive'],['create_guest_request','Create Guest Request','create'],['create_upsell','Create Upsell','create']],
  restaurant_crm:[['refresh_metrics','Refresh Visit Metrics','derive'],['refresh_preferences','Refresh Food Preferences','derive'],['create_segment','Create Segment','create']],
  customer_ltv:[['recalculate_ltv','Recalculate LTV','derive'],['refresh_snapshot','Refresh Snapshot','derive']],
  lead_management:[['qualify','Qualify','status'],['convert_customer','Convert to Customer','derive'],['create_followup','Create Follow-up','create'],['mark_lost','Mark Lost','status']],
  followups:[['complete','Complete','status'],['reschedule','Reschedule','update'],['escalate','Escalate','notify']],
  corporate_crm:[['open_account','Open Account','navigate'],['create_contract','Create Contract','create'],['schedule_review','Schedule Review','notify']],
  partner_crm:[['onboard','Onboard','update'],['calculate_commission','Calculate Commission','derive'],['create_settlement','Create Settlement','create']],
  loyalty:[['issue_points','Issue Points','derive'],['redeem_reward','Redeem Reward','derive'],['reverse_transaction','Reverse Transaction','derive'],['refresh_tier','Refresh Tier','derive']],
  offers_coupons:[['validate_coupon','Validate Coupon','derive'],['deactivate','Deactivate','update'],['view_redemptions','View Redemptions','navigate']],
  marketing_automation:[['activate_campaign','Activate Campaign','status'],['pause_campaign','Pause Campaign','status'],['run_audience','Run Audience','derive'],['view_attribution','View Attribution','navigate']],
  whatsapp_crm:[['open_conversation','Open Conversation','navigate'],['retry_failed','Retry Failed','derive'],['mark_read','Mark Read','update'],['create_template','Create Template','create']],
  reputation:[['generate_reply','Generate Reply','provider'],['approve_reply','Approve Reply','update'],['publish_reply','Publish Reply','provider'],['create_recovery','Create Recovery','create']],
  guest_relations:[['assign','Assign','update'],['start_sla','Start SLA','derive'],['escalate','Escalate','notify'],['resolve','Resolve','status'],['create_recovery','Create Recovery','create']],
  segmentation:[['preview_audience','Preview Audience','derive'],['refresh_membership','Refresh Membership','derive'],['activate_campaign','Activate Campaign','derive']],
  churn:[['recompute_churn','Recompute Churn','derive'],['view_factors','View Factors','derive'],['create_retention','Create Retention Action','create']],
  vip:[['qualify_vip','Qualify VIP','derive'],['assign_manager','Assign Manager','update'],['add_amenity','Add Amenity','update']],
  revenue_management:[['generate_recommendation','Generate Recommendation','derive'],['approve_rate','Approve Rate','update'],['override_rate','Override Rate','update'],['publish_rate','Publish Rate','update']],
  upselling:[['find_eligible','Find Eligible Guests','derive'],['send_offer','Send Offer','derive'],['record_acceptance','Record Acceptance','create'],['cancel_offer','Cancel Offer','update']],
  cross_selling:[['preview_matches','Preview Matches','derive'],['generate_offers','Generate Offers','create'],['send_offers','Send Offers','derive'],['view_attribution','View Attribution','navigate']],
  event_crm:[['create_quote','Create Quote','create'],['approve_proposal','Approve Proposal','update'],['schedule_followup','Schedule Follow-up','notify'],['record_deposit','Record Deposit','create']],
  omnichannel_timeline:[['open_timeline','Open Customer Timeline','navigate'],['rebuild_timeline','Rebuild Timeline','derive'],['filter_source','Filter by Source','derive']],
  consent_privacy:[['grant_consent','Grant Consent','update'],['withdraw_consent','Withdraw Consent','update'],['export_request','Export Data Request','create'],['delete_request','Delete Data Request','create']],
  relationship_manager:[['assign_owner','Assign Owner','update'],['rebalance','Rebalance Workload','derive'],['escalate_sla','Escalate SLA','notify'],['reassign','Reassign','update']],
  advanced_analytics:[['refresh_metrics','Refresh Metrics','derive'],['compare_periods','Compare Periods','derive'],['open_cohorts','Open Cohorts','derive'],['export_report','Export Report','navigate']],
  ai_crm:[['generate_summary','Generate Summary','provider'],['next_best_action','Generate Next Best Action','provider'],['run_insight','Run Insight','provider'],['approve_action','Approve Action','update']],
  revenue_forecasting:[['generate_forecast','Generate Forecast','derive'],['refresh_forecast','Refresh Forecast','derive'],['compare_accuracy','Compare Accuracy','derive'],['approve_forecast','Approve Forecast','update']],
  competitor_intelligence:[['collect_rates','Collect Rates','provider'],['normalize_rates','Normalize Rates','derive'],['run_parity','Run Parity','derive'],['create_alert','Create Alert','notify']],
  'hotel-booking':[['check_availability','Check Availability','derive'],['create_hold','Create Hold','derive'],['confirm_booking','Confirm Booking','update'],['cancel_booking','Cancel Booking','update'],['refund','Refund','provider']],
  'hotel-management-suite':[['front_desk','Open Front Desk','navigate'],['housekeeping','Open Housekeeping','navigate'],['folios','Open Folios','navigate'],['night_audit','Run Night Audit','derive']],
  'hotel-pms':[['check_in','Check In','rpc'],['room_move','Room Move','rpc'],['check_out','Check Out','rpc'],['no_show','No Show','rpc'],['cancel','Cancel','rpc'],['post_folio','Post Folio','create']],
  'restaurant-reservation':[['confirm','Confirm','status'],['seat','Seat','status'],['move_table','Move Table','update'],['no_show','No Show','status'],['cancel','Cancel','status'],['complete','Complete','status']],
  'food-delivery':[['accept','Accept','status'],['preparing','Mark Preparing','status'],['ready','Mark Ready','status'],['assign_rider','Assign Rider','update'],['picked_up','Picked Up','status'],['delivered','Delivered','status'],['cancel','Cancel','status']],
  'restaurant-store':[['open_storefront','Open Storefront','navigate'],['publish','Publish','update'],['unpublish','Unpublish','update'],['preview','Preview Store','navigate']],
  'anaira-pos':[['open_pos','Open POS','navigate'],['open_order','Open Order','navigate'],['sync_crm','Sync CRM','derive'],['view_order','View Order','navigate']],
  'channel-manager':[['sync_inventory','Sync Inventory','provider'],['sync_rates','Sync Rates','provider'],['sync_reservations','Sync Reservations','provider'],['run_parity','Run Parity','derive'],['retry_failed','Retry Failed','provider']],
  'seo-system':[['run_crawl','Run Crawl','provider'],['sync_gsc','Sync GSC','provider'],['sync_ga4','Sync GA4','provider'],['track_rankings','Track Rankings','provider'],['generate_content','Generate Content','provider'],['generate_schema','Generate Schema','derive']],
  'ai-review-system':[['sync_reviews','Sync Reviews','provider'],['ai_classification','Run AI Classification','provider'],['generate_replies','Generate Replies','provider'],['delivery_worker','Run Delivery Worker','derive'],['sla_worker','Run SLA Worker','derive']]
};

const label=(s)=>s.replaceAll('_',' ').replace(/\b\w/g,m=>m.toUpperCase());

export function getPluginDefinition(pluginKey){
  const reg=pluginRegistry.plugins[pluginKey];
  if(!reg)return null;
  const raw=domainActions[pluginKey]||[];
  const actions=raw.map(([id,name,kind])=>({id,name,kind}));
  const settingsSchema=getEnhancedSettings(pluginKey,reg.settingsSchema||[]);
  const primaryKey=primaryKeys[pluginKey]||['id'];
  const tenantColumn=tenantColumns[pluginKey]||((reg.fields||[]).includes('tenant_id')?'tenant_id':((reg.fields||[]).includes('restaurant_id')?'restaurant_id':null));
  const statusField=stringStatusFields[pluginKey]||null;
  const createFields=pluginKey==='hotel-booking'?[]:(reg.fields||[]).filter(f=>!['id','tenant_id','restaurant_id','created_at','updated_at','status','state'].includes(f));
  return {...reg,settingsSchema,primaryKey,tenantColumn,statusField,actions,createFields,actionNames:actions.map(x=>x.name),label};
}

export function getAllPluginDefinitions(){return Object.keys(pluginRegistry.plugins).map(getPluginDefinition);}
