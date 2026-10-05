import {randomUUID} from 'node:crypto';
import {db} from '../../../../../lib/server/provider';
import {requireTenant} from '../../../../../lib/server/auth';
import {getPluginDefinition} from '../../../../pluginEngine';

export const runtime='nodejs';
const iso=()=>new Date().toISOString();
const date=()=>iso().slice(0,10);

async function audit(s,tenantId,user,entityType,entityId,action,before=null,after=null){
  await s.from('crm_audit_logs').insert({tenant_id:tenantId,actor_id:user?.id||null,entity_type:entityType,entity_id:entityId==null?null:String(entityId),action,before_data:before,after_data:after}).catch(()=>{});
}
async function notify(s,tenantId,title,body,url='/plugins'){await s.from('crm_notifications').insert({tenant_id:tenantId,notification_type:'plugin_action',title,body,severity:'info',action_url:url}).catch(()=>{});}
function scoped(q,def,tenantId){return def.tenantColumn?q.eq(def.tenantColumn,tenantId):q;}
function keyFilter(q,def,row){for(const k of def.primaryKey||['id'])q=q.eq(k,row[k]);return q;}
async function getRow(s,def,tenantId,recordKey){let q=scoped(s.from(def.dataTable).select('*'),def,tenantId);for(const k of def.primaryKey||['id']){if(recordKey?.[k]==null)throw new Error(`Missing record key: ${k}`);q=q.eq(k,recordKey[k]);}const {data,error}=await q.maybeSingle();if(error)throw error;if(!data)throw new Error('Record not found for this tenant');return data;}

async function refreshCustomerValue(s,tenantId,customerId,propertyId=null){
  const [{data:c},{data:r},{data:stays}]=await Promise.all([
    s.from('crm_customers').select('*').eq('tenant_id',tenantId).eq('id',customerId).maybeSingle(),
    s.from('crm_restaurant_customer_metrics').select('*').eq('tenant_id',tenantId).eq('customer_id',customerId).eq(propertyId ? 'property_id' : 'tenant_id', propertyId || tenantId).maybeSingle(),
    s.from('crm_guest_stays').select('total_amount,nights,booking_status').eq('tenant_id',tenantId).eq('customer_id',customerId).eq(propertyId ? 'property_id' : 'tenant_id', propertyId || tenantId).limit(1000)
  ]);
  if(!c)throw new Error('Customer not found');
  const stayRows=stays||[]; const hotel=Math.max(Number(c.total_hotel_revenue||0),stayRows.filter(x=>!['cancelled','no_show'].includes(x.booking_status)).reduce((a,x)=>a+Number(x.total_amount||0),0));
  const restaurant=Math.max(Number(c.total_restaurant_revenue||0),Number(r?.lifetime_spend||0)); const visits=Number(r?.total_visits||c.total_restaurant_visits||0);
  const nights=stayRows.filter(x=>!['cancelled','no_show'].includes(x.booking_status)).reduce((a,x)=>a+Number(x.nights||0),0); const total=hotel+restaurant; const ltv=Number((total*Math.max(1,1+Math.min(3,visits/10))).toFixed(2));
  const {data,error}=await s.from('crm_customer_value_snapshots').upsert({tenant_id:tenantId,customer_id:customerId,snapshot_date:date(),property_id:propertyId||c.property_id,hotel_revenue:hotel,restaurant_revenue:restaurant,event_revenue:0,ancillary_revenue:0,total_revenue:total,visit_count:visits,stay_nights:nights,calculated_ltv:ltv},{onConflict:'customer_id,snapshot_date'}).select().maybeSingle();
  if(error)throw error; await s.from('crm_customers').update({total_restaurant_revenue:restaurant,total_stays:stayRows.length,total_restaurant_visits:visits,updated_at:iso()}).eq('tenant_id',tenantId).eq('id',customerId); return data||{customer_id:customerId,calculated_ltv:ltv};
}

async function refreshInsights(s,tenantId,customerId,propertyId=null){
  const [{data:c},{data:r}]=await Promise.all([s.from('crm_customers').select('*').eq('tenant_id',tenantId).eq('id',customerId).maybeSingle(),s.from('crm_restaurant_customer_metrics').select('*').eq('tenant_id',tenantId).eq('customer_id',customerId).eq(propertyId ? 'property_id' : 'tenant_id', propertyId || tenantId).maybeSingle()]);
  if(!c)throw new Error('Customer not found');
  const facts=[
    {type:'value',key:'customer_value',value:`Hotel ₹${Number(c.total_hotel_revenue||0).toFixed(2)} + Restaurant ₹${Number(Math.max(Number(c.total_restaurant_revenue||0),Number(r?.lifetime_spend||0))).toFixed(2)}`,confidence:.98},
    {type:'behavior',key:'restaurant_frequency',value:`${Number(r?.total_visits||0)} restaurant visits`,confidence:.95},
    {type:'relationship',key:'vip_status',value:c.vip?'VIP customer':'Standard customer',confidence:1}
  ];
  for(const x of facts)await s.from('crm_customer_insights').upsert({tenant_id:tenantId,customer_id:customerId,property_id:propertyId||c.property_id,insight_type:x.type,insight_key:x.key,insight_value:x.value,confidence:x.confidence,source:'rules-v1',observed_at:iso()},{onConflict:'tenant_id,customer_id,insight_key'});
  return facts;
}

async function recomputeChurn(s,tenantId,customerId,propertyId=null){
  const [{data:m},{data:c}]=await Promise.all([s.from('crm_restaurant_customer_metrics').select('last_visit_at,complaints_count,total_visits').eq('tenant_id',tenantId).eq('customer_id',customerId).eq(propertyId ? 'property_id' : 'tenant_id', propertyId || tenantId).maybeSingle(),s.from('crm_customers').select('total_stays').eq('tenant_id',tenantId).eq('id',customerId).maybeSingle()]);
  if(!c)throw new Error('Customer not found'); const recency=m?.last_visit_at?Math.max(0,(Date.now()-new Date(m.last_visit_at).getTime())/86400000):180;
  const score=Math.max(0,Math.min(.99,Math.min(.55,recency/180*.55)+Math.min(.2,(Number(m?.complaints_count||0)/5)*.2)+(Number(c.total_stays||0)===0?.1:0)));
  const risk=score>=.75?'high':score>=.5?'medium':'low'; const factors=[{key:'recency_days',value:Number(recency.toFixed(1))},{key:'complaints',value:Number(m?.complaints_count||0)},{key:'total_stays',value:Number(c.total_stays||0)}];
  const {data,error}=await s.from('crm_churn_scores').upsert({tenant_id:tenantId,customer_id:customerId,score,risk_level:risk,factors,calculated_at:iso(),property_id:propertyId||c.property_id},{onConflict:'tenant_id,customer_id'}).select().maybeSingle();if(error)throw error;return data||{customer_id:customerId,score,risk_level:risk,factors};
}

async function aiCustomer(s,tenantId,user,customerId,mode){
  if(!process.env.OPENAI_API_KEY)throw new Error('OPENAI_API_KEY is required for AI CRM actions');
  const [{data:c},{data:stays},{data:r}]=await Promise.all([s.from('crm_customers').select('*').eq('tenant_id',tenantId).eq('id',customerId).maybeSingle(),s.from('crm_guest_stays').select('room_number,check_in_date,check_out_date,total_amount,booking_status').eq('tenant_id',tenantId).eq('customer_id',customerId).eq(propertyId ? 'property_id' : 'tenant_id', propertyId || tenantId).limit(25),s.from('crm_restaurant_customer_metrics').select('*').eq('tenant_id',tenantId).eq('customer_id',customerId).eq(propertyId ? 'property_id' : 'tenant_id', propertyId || tenantId).maybeSingle()]);
  if(!c)throw new Error('Customer not found'); const prompt=mode==='summary'?'Create a concise CRM customer summary as JSON {summary,confidence}.':mode==='next_best_action'?'Return JSON {action,recommendation,confidence} with the best next CRM action.':'Return JSON {insights:[{summary,recommendation,confidence}]} with explainable CRM insights.';
  const resp=await fetch('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${process.env.OPENAI_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({model:process.env.OPENAI_MODEL||'gpt-5-mini',input:`${prompt}\nCustomer:${JSON.stringify(c)}\nStays:${JSON.stringify(stays||[])}\nRestaurant:${JSON.stringify(r||{})}`} )});
  const j=await resp.json();if(!resp.ok)throw new Error(j.error?.message||'OpenAI request failed');let out;try{out=JSON.parse(j.output_text||'{}')}catch{throw new Error('AI returned invalid JSON');}
  if(mode!=='insights'){const text=String(out.summary||out.action||out.recommendation||'');const {data,error}=await s.from('crm_ai_insights').insert({tenant_id:tenantId,customer_id:customerId,insight_type:mode,summary:text,recommendation:mode==='next_best_action'?String(out.recommendation||out.action||''):null,confidence:Number(out.confidence??.8),model_name:process.env.OPENAI_MODEL||'gpt-5-mini',model_version:'runtime-v1',input_snapshot:{customer:c,stays:stays||[],restaurant:r||{}},created_at:iso()}).select().single();if(error)throw error;await audit(s,tenantId,user,'crm_ai_insights',data.id,`ai_${mode}`,null,data);return data;}
  const list=Array.isArray(out.insights)?out.insights:[];for(const x of list.slice(0,5))await s.from('crm_ai_insights').insert({tenant_id:tenantId,customer_id:customerId,insight_type:'ai_insight',summary:String(x.summary||''),recommendation:x.recommendation?String(x.recommendation):null,confidence:Number(x.confidence??.7),model_name:process.env.OPENAI_MODEL||'gpt-5-mini',model_version:'runtime-v1',input_snapshot:{customer:c,stays:stays||[],restaurant:r||{}},created_at:iso()});return {count:Math.min(5,list.length)};
}

async function callInternal(req,path,body,cron=false){const headers=new Headers({'content-type':'application/json'});const auth=req.headers.get('authorization');if(cron&&process.env.CRON_SECRET)headers.set('authorization',`Bearer ${process.env.CRON_SECRET}`);else if(auth)headers.set('authorization',auth);const res=await fetch(new URL(path,req.url),{method:'POST',headers,body:JSON.stringify(body)});const json=await res.json().catch(()=>({}));if(!res.ok||json.ok===false)throw new Error(json.error||`Delegated request failed (${res.status})`);return json;}

const statusMap={confirm:'confirmed',seat:'seated',no_show:'no_show',cancel:'cancelled',complete:'completed',qualify:'qualified',mark_lost:'lost',activate_campaign:'active',pause_campaign:'paused',resolve:'resolved',check_in:'checked_in',check_out:'checked_out',accept:'accepted',preparing:'preparing',ready:'ready',picked_up:'picked_up',delivered:'delivered',publish:'published',unpublish:'draft'};

export async function POST(req){
  try{
    const body=await req.json(); const {pluginKey,tenantId,actionId,recordKey=null,payload={}}=body||{};
    const def=getPluginDefinition(pluginKey);if(!def)throw new Error('Unknown plugin');if(!tenantId||!actionId)throw new Error('tenantId and actionId are required');
    const {user}=await requireTenant(req,tenantId);const action=def.actions.find(a=>a.id===actionId);if(!action)throw new Error(`Action ${actionId} is not registered`);
    const authHeader=req.headers.get('authorization')||'';const accessToken=authHeader.startsWith('Bearer ')?authHeader.slice(7).trim():null;const s=db(accessToken);const crmChildKeys=new Set(['customer_360','customer_intelligence','hotel_guest_crm','restaurant_crm','customer_ltv','lead_management','followups','corporate_crm','partner_crm','loyalty','offers_coupons','marketing_automation','whatsapp_crm','reputation','guest_relations','segmentation','churn','vip','revenue_management','upselling','cross_selling','event_crm','omnichannel_timeline','consent_privacy','relationship_manager','advanced_analytics','ai_crm','revenue_forecasting','competitor_intelligence']);const pluginCodes=crmChildKeys.has(pluginKey)?[pluginKey,'crm']:[pluginKey];const {data:states}=await s.from('restaurant_plugins').select('enabled,config,plugin_code').eq('restaurant_id',tenantId).in('plugin_code',pluginCodes);const state=states?.find(x=>x.plugin_code===pluginKey)||states?.find(x=>x.plugin_code==='crm');if(!state?.enabled)throw new Error('Plugin is disabled for this property');
    const {data:settingsRows}=await s.from('plugin_settings').select('config,custom_settings,plugin_code').eq('restaurant_id',tenantId).in('plugin_code',pluginCodes);const ps=settingsRows?.find(x=>x.plugin_code===pluginKey)||settingsRows?.find(x=>x.plugin_code==='crm');const settings={...(state.config?.settings||{}),...(ps?.config?.settings||{}),...(ps?.custom_settings||{})};
    if(settings.automation_enabled===false&&['refresh_membership','run_audience','prearrival_check','delivery_worker','sla_worker'].includes(actionId))throw new Error('Automation is disabled in plugin settings');
    let row=null;if(recordKey)row=await getRow(s,def,tenantId,recordKey);let result={ok:true,pluginKey,actionId};

    if(action.kind==='navigate'){
      result.navigateTo=pluginKey==='crm'?'/crm':pluginKey==='restaurant-store'?'/restaurant-stores':def.route;return Response.json(result);
    }
    if(action.kind==='notify'){
      await notify(s,tenantId,`${def.name}: ${action.name}`,payload.message||`${action.name} requires attention.`,def.route,'warning');
      await audit(s,tenantId,user,def.dataTable,row?.id||null,actionId,null,{notified:true});
      return Response.json({...result,result:{notified:true}});
    }
    if(action.kind==='status'){
      if(!row)throw new Error('Select a record first');if(!def.statusField)throw new Error('No safe string status field configured for this plugin');const next=statusMap[actionId];if(!next)throw new Error(`No transition mapped for ${actionId}`);
      const patch={[def.statusField]:next};if(pluginKey==='guest_relations'&&actionId==='resolve')patch.resolved_at=iso();let q=s.from(def.dataTable).update(patch);q=keyFilter(q,def,row);q=scoped(q,def,tenantId);const {data,error}=await q.select().maybeSingle();if(error)throw error;await audit(s,tenantId,user,def.dataTable,row[def.primaryKey[0]],actionId,row,data);result.result=data;return Response.json(result);
    }
    if(action.kind==='rpc'){
      if(!row)throw new Error('Select a PMS reservation');const pms={check_in:'check_in',room_move:'room_move',check_out:'checkout',no_show:'no_show',cancel:'cancel'}[actionId];if(!pms)throw new Error('Unsupported PMS action');const roomId=payload.roomId||row.room_id||null;if(['check_in','room_move'].includes(pms)&&!roomId)throw new Error('roomId is required');const {data,error}=await s.rpc('anaira_phase13_pms_transition',{p_restaurant_id:tenantId,p_reservation_id:row.id,p_action:pms,p_room_id:roomId,p_notes:payload.notes||null});if(error)throw error;result.result=data;return Response.json(result);
    }
    if(action.kind==='provider'){
      if(pluginKey==='seo-system'){
        const map={run_crawl:['/api/seo/crawl',{siteId:row?.id,maxPages:settings.crawl_max_pages||100}],sync_gsc:['/api/seo/gsc',{siteId:row?.id}],sync_ga4:['/api/seo/ga4',{siteId:row?.id}],track_rankings:['/api/seo/rank-sync',{siteId:row?.id}],generate_content:['/api/seo/ai-content',{siteId:row?.id,pageId:payload.pageId||null,keyword:payload.keyword||'hospitality SEO',brief:payload.brief||''}]};const x=map[actionId];if(!x)throw new Error('Unsupported SEO provider action');result.result=await callInternal(req,x[0],x[1]);
      }else if(pluginKey==='ai-review-system'){
        if(actionId==='sync_reviews'){const {data:src}=await s.from('crm_review_sources').select('id').eq('tenant_id',tenantId).eq('active',true).order('created_at').limit(1).maybeSingle();if(!src)throw new Error('No active review source');result.result=await callInternal(req,'/api/reviews/sync',{tenantId,sourceId:src.id});}
        else if(actionId==='ai_classification'||actionId==='generate_replies'){if(!row?.id)throw new Error('Select a review');result.result=await callInternal(req,'/api/reviews/ai',{reviewId:row.id});}
        else if(actionId==='delivery_worker')result.result=await callInternal(req,'/api/reviews/worker',{},true);
        else if(actionId==='sla_worker')result.result=await callInternal(req,'/api/reviews/sla',{},true);
        else throw new Error('Unsupported AI Review action');
      }else if(pluginKey==='ai_crm'){
        if(!row?.customer_id)throw new Error('Select a customer-linked record');result.result=await aiCustomer(s,tenantId,user,row.customer_id,actionId==='generate_summary'?'summary':actionId==='next_best_action'?'next_best_action':'insights');
      }else if(pluginKey==='reputation'){if(!row?.id)throw new Error('Select a review');if(actionId==='generate_reply'){result.result=await callInternal(req,'/api/reviews/ai',{reviewId:row.id});}else if(actionId==='publish_reply'){result.result=await callInternal(req,'/api/reviews/publish',{reviewId:row.id});}else throw new Error('Unsupported reputation provider action');
      }else if(pluginKey==='competitor_intelligence'){
        const endpoint=process.env.COMPETITOR_RATES_API_URL;if(!endpoint)throw new Error('COMPETITOR_RATES_API_URL is required for live competitor collection');const u=new URL(endpoint);u.searchParams.set('tenant_id',tenantId);u.searchParams.set('date',row?.stay_date||payload.stayDate||date());const headers=process.env.COMPETITOR_RATES_API_KEY?{Authorization:`Bearer ${process.env.COMPETITOR_RATES_API_KEY}`}:{}; // provider response is intentionally never fabricated
        const res=await fetch(u,{headers});const json=await res.json().catch(()=>({}));if(!res.ok)throw new Error(json.error||'Competitor provider request failed');result.result=json;
      }else if(pluginKey==='channel-manager'){
        const endpoint=process.env.CHANNEL_MANAGER_API_URL;if(!endpoint)throw new Error('CHANNEL_MANAGER_API_URL is required for a live OTA/channel adapter');const headers={'content-type':'application/json',...(process.env.CHANNEL_MANAGER_API_KEY?{Authorization:`Bearer ${process.env.CHANNEL_MANAGER_API_KEY}`}: {})};const res=await fetch(endpoint,{method:'POST',headers,body:JSON.stringify({tenantId,action:actionId,record:row,payload})});const json=await res.json().catch(()=>({}));if(!res.ok||json.ok===false)throw new Error(json.error||'Channel manager provider rejected the request');result.result=json;
      }else if(pluginKey==='hotel-booking'&&actionId==='refund'){
        if(!row?.payment_intent_id)throw new Error('Booking has no payment intent');const endpoint=process.env.PAYMENT_REFUND_API_URL;if(!endpoint)throw new Error('PAYMENT_REFUND_API_URL is required for live refunds');const res=await fetch(endpoint,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({tenantId,paymentIntentId:row.payment_intent_id,amount:row.amount,currency:row.currency})});const json=await res.json().catch(()=>({}));if(!res.ok||json.ok===false)throw new Error(json.error||'Payment provider rejected refund');result.result=json;
      }else if(pluginKey==='revenue_management'&&actionId==='publish_rate'){
        const endpoint=process.env.RATE_PUBLISH_API_URL;if(!endpoint)throw new Error('RATE_PUBLISH_API_URL is required for external rate publishing');const headers={'content-type':'application/json',...(process.env.RATE_PUBLISH_API_KEY?{Authorization:`Bearer ${process.env.RATE_PUBLISH_API_KEY}`}: {})};const res=await fetch(endpoint,{method:'POST',headers,body:JSON.stringify({tenantId,recommendation:row})});const json=await res.json().catch(()=>({}));if(!res.ok||json.ok===false)throw new Error(json.error||'Rate publisher rejected request');result.result=json;
      }else throw new Error('This provider action needs its real provider credentials/configuration');
      await audit(s,tenantId,user,def.dataTable,row?.id||null,actionId,null,result.result);return Response.json(result);
    }
    if(pluginKey==='hotel-booking'&&actionId==='confirm_booking'){
      if(!row?.id) throw new Error('Select a booking transaction');
      const {data:finalized,error:fe}=await s.rpc('anaira_finalize_hotel_booking_payment',{p_transaction_id:row.id,p_method:'pay_at_hotel',p_receipt_path:null,p_note:'Confirmed from Hotel Booking Engine Control'});
      if(fe) throw fe;
      result.result=finalized;
      await audit(s,tenantId,user,def.dataTable,row.id,actionId,row,finalized);
      return Response.json(result);
    }
    if(action.kind==='update'){
      if(!row)throw new Error('Select a record first');const patch={};
      if(actionId==='assign_owner'){if(!payload.staffId)throw new Error('staffId is required');patch.staff_id=payload.staffId;patch.active=true;patch.assigned_at=iso();}
      else if(actionId==='assign_manager'){if(!payload.staffId)throw new Error('staffId is required');patch.dedicated_manager=payload.staffId;}
      else if(actionId==='add_amenity'){const a=String(payload.amenity||'').trim();if(!a)throw new Error('amenity is required');patch.welcome_amenities=[...(Array.isArray(row.welcome_amenities)?row.welcome_amenities:[]),a];}
      else if(actionId==='approve_rate'){patch.status='approved';patch.approved_by=user.id;patch.approved_at=iso();}
      else if(actionId==='override_rate'){const rate=Number(payload.rate);if(!Number.isFinite(rate)||rate<=0)throw new Error('Positive override rate required');patch.recommended_rate=rate;patch.status='pending_approval';}
      else if(actionId==='publish'){patch.published=true;patch.status='published';}
      else if(actionId==='unpublish'){patch.published=false;patch.status='draft';}
      else if(actionId==='mark_read'){patch.status='read';patch.read_at=iso();}
      else if(actionId==='approve_reply'){patch.reply_status='approved';patch.replied_at=iso();}
      else if(actionId==='assign'){patch.assigned_to=payload.staffId||payload.userId||null;}
      else if(actionId==='grant_consent'||actionId==='withdraw_consent'){patch.status=actionId==='grant_consent'?'granted':'withdrawn';patch.captured_at=iso();}
      else if(actionId==='onboard'){patch.active=true;}
      else if(actionId==='reschedule'){patch.scheduled_at=new Date(Date.now()+24*3600000).toISOString();patch.status='queued';}
      else if(actionId==='escalate'){patch.status='escalated';}
      else if(actionId==='cancel_offer'){patch.status='cancelled';}
      else if(actionId==='approve_proposal'){patch.stage='approved';}
      else if(actionId==='approve_action'){patch.status='approved';patch.approved_by=user.id;patch.approved_at=iso();}
      else if(actionId==='approve_forecast'){patch.status='approved';patch.approved_by=user.id;patch.approved_at=iso();}
      else if(actionId==='confirm_booking'){patch.state='confirmed';patch.updated_at=iso();}
      else if(actionId==='cancel_booking'){patch.state='cancelled';patch.updated_at=iso();}
      else if(actionId==='reassign'){if(!payload.staffId)throw new Error('staffId is required');patch.staff_id=payload.staffId;patch.active=true;patch.assigned_at=iso();}
      else if(actionId==='move_table'){if(!payload.tableId)throw new Error('tableId is required');patch.table_id=payload.tableId;}
      else if(actionId==='assign_rider'){if(!payload.riderId)throw new Error('riderId is required');patch.rider_id=payload.riderId;patch.status='assigned';}
      else if(actionId==='publish_forecast'){patch.status='published';patch.published_at=iso();}
      else throw new Error(`No update handler for ${pluginKey}/${actionId}`);
      let q=keyFilter(s.from(def.dataTable).update(patch),def,row);q=scoped(q,def,tenantId);const {data,error}=await q.select().maybeSingle();if(error)throw error;await audit(s,tenantId,user,def.dataTable,row[def.primaryKey[0]],actionId,row,data);result.result=data;return Response.json(result);
    }
    if(action.kind==='create'){
      if(pluginKey==='hotel-pms'&&actionId==='post_folio'){if(!row?.id)throw new Error('Select a reservation');if(!payload.folioId||!payload.description)throw new Error('folioId and description are required');const quantity=Number(payload.quantity||1),unit=Number(payload.unitPrice||0),tax=Number(payload.tax||0),total=quantity*unit+tax;const {data,error}=await s.from('hms_folio_items').insert({folio_id:payload.folioId,item_type:payload.itemType||'charge',description:payload.description,quantity,unit_price:unit,tax,total,source_system:'crm',source_id:row.id}).select().single();if(error)throw error;await s.from('hms_folios').update({subtotal:total,status:'open',balance:total,updated_at:iso()}).eq('id',payload.folioId).eq('restaurant_id',tenantId);result.result=data;}
      else if(pluginKey==='followups'&&actionId==='create_followup'){const {data,error}=await s.from('crm_followup_events').insert({tenant_id:tenantId,customer_id:row?.customer_id||payload.customerId||null,lead_id:row?.lead_id||payload.leadId||null,sequence_id:payload.sequenceId||null,scheduled_at:payload.scheduledAt||new Date(Date.now()+86400000).toISOString(),status:'queued'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='hotel_guest_crm'&&actionId==='create_guest_request'){const customerId=row?.customer_id||payload.customerId;if(!customerId)throw new Error('customerId is required');const {data,error}=await s.from('crm_guest_requests').insert({tenant_id:tenantId,customer_id:customerId,stay_id:row?.id||payload.stayId||null,request_type:payload.requestType||'general',description:payload.description||'Guest request',priority:payload.priority||'normal',status:'open'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='hotel_guest_crm'&&actionId==='create_upsell'){const customerId=row?.customer_id||payload.customerId;if(!customerId)throw new Error('customerId is required');const {data,error}=await s.from('crm_upsell_events').insert({tenant_id:tenantId,customer_id:customerId,offer_id:payload.offerId||null,reference_type:'guest_crm',reference_id:row?.id||null,status:'proposed'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='restaurant_crm'&&actionId==='create_segment'){const {data,error}=await s.from('crm_segments').insert({tenant_id:tenantId,property_id:payload.propertyId||row?.property_id||null,name:payload.name||`Restaurant Customers ${date()}`,definition:{domain:'restaurant',customer_ids:row?.customer_id?[row.customer_id]:[]},active:true}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='corporate_crm'&&actionId==='create_contract'){if(!row?.id)throw new Error('Select a corporate account');const {data,error}=await s.from('crm_corporate_contracts').insert({corporate_account_id:row.id,contract_number:`CORP-${Date.now()}`,start_date:date(),end_date:new Date(Date.now()+365*86400000).toISOString().slice(0,10),negotiated_terms:{payment_terms:row.payment_terms,credit_limit:row.credit_limit},status:'draft'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='partner_crm'&&actionId==='create_settlement'){if(!row?.id)throw new Error('Select a partner');const {data:books}=await s.from('crm_partner_bookings').select('booking_amount,commission_amount').eq('tenant_id',tenantId).eq('partner_id',row.id).eq('status','completed');const gross=(books||[]).reduce((a,x)=>a+Number(x.booking_amount||0),0),comm=(books||[]).reduce((a,x)=>a+Number(x.commission_amount||0),0);const {data,error}=await s.from('crm_partner_settlements').insert({tenant_id:tenantId,partner_id:row.id,period_start:new Date(Date.now()-30*86400000).toISOString().slice(0,10),period_end:date(),gross_amount:gross,commission_amount:comm,status:'pending'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='whatsapp_crm'&&actionId==='create_template'){const {data,error}=await s.from('crm_message_templates').insert({tenant_id:tenantId,channel:'whatsapp',template_key:payload.templateKey||`anaira_${Date.now()}`,language_code:payload.language||'en',body:payload.body||'Hello {{customer_name}}',variables:payload.variables||[],active:false}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='reputation'&&actionId==='create_recovery'){const {data,error}=await s.from('crm_service_recovery_cases').insert({tenant_id:tenantId,property_id:payload.propertyId||row?.property_id||null,customer_id:row?.customer_id||null,complaint_id:null,recovery_type:'review_recovery',compensation_amount:Number(payload.value||0),status:'open'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='guest_relations'&&actionId==='create_recovery'){const {data,error}=await s.from('crm_service_recovery_cases').insert({tenant_id:tenantId,property_id:payload.propertyId||row?.property_id||null,complaint_id:row?.id,customer_id:row?.customer_id||null,recovery_type:payload.recoveryType||'service_credit',compensation_amount:Number(payload.value||0),status:'open'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='cross_selling'&&actionId==='generate_offers'){if(!row?.id)throw new Error('Select a rule');const {data:customers}=await s.from('crm_customers').select('id').eq('tenant_id',tenantId).limit(250);for(const c of customers||[])await s.from('crm_upsell_events').insert({tenant_id:tenantId,customer_id:c.id,offer_id:null,reference_type:'cross_sell_rule',reference_id:row.id,status:'proposed'});result.result={offersGenerated:(customers||[]).length};}
      else if(pluginKey==='event_crm'&&actionId==='create_quote'){if(!row?.id)throw new Error('Select an event');const {data,error}=await s.from('crm_event_quotes').insert({event_id:row.id,quote_id:payload.quoteId||randomUUID(),package_definition:payload.packageDefinition||{event_name:row.name,expected_guests:row.expected_guests,estimated_value:row.estimated_value}}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='consent_privacy'){const {data,error}=await s.from('crm_data_requests').insert({tenant_id:tenantId,customer_id:row?.customer_id||payload.customerId,request_type:actionId==='export_request'?'export':'delete',status:'queued',requested_at:iso(),payload}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='upselling'&&actionId==='record_acceptance'){if(!row?.id)throw new Error('Select an offer');const {data,error}=await s.from('crm_upsell_events').insert({tenant_id:tenantId,customer_id:row.customer_id||payload.customerId,offer_id:row.id,reference_type:'upsell',reference_id:row.id,status:'accepted'}).select().single();if(error)throw error;result.result=data;}
      else throw new Error(`No create handler for ${pluginKey}/${actionId}`);
      await audit(s,tenantId,user,def.dataTable,row?.id||null,actionId,null,result.result);return Response.json(result);
    }
    if(action.kind==='derive'){
      if((pluginKey==='crm'&&actionId==='refresh_value')||(pluginKey==='customer_ltv'&&(actionId==='recalculate_ltv'||actionId==='refresh_snapshot'))){const customerId=row?.customer_id||row?.id;if(!customerId)throw new Error('Select a customer');result.result=await refreshCustomerValue(s,tenantId,customerId,payload.propertyId||row?.property_id||null);}
      else if(pluginKey==='customer_360'&&actionId==='refresh_timeline'){if(!row?.id)throw new Error('Select a customer');await s.rpc('anaira_refresh_global_customer_links',{p_tenant_id:tenantId,p_customer_id:row.id});await s.from('crm_timeline_events').insert({tenant_id:tenantId,property_id:payload.propertyId||row.property_id||null,customer_id:row.id,event_type:'customer_refresh',source_system:'crm',title:'Customer 360 refreshed'});result.result={refreshed:true};}
      else if(pluginKey==='customer_360'&&actionId==='refresh_value'){result.result=await refreshCustomerValue(s,tenantId,row?.id,payload.propertyId||row?.property_id||null);}
      else if(pluginKey==='customer_intelligence'){if(!row?.customer_id)throw new Error('Select a customer insight');result.result=await refreshInsights(s,tenantId,row.customer_id,payload.propertyId||row?.property_id||null);}
      else if(pluginKey==='hotel_guest_crm'&&actionId==='prearrival_check'){result.result=await s.rpc('anaira_queue_prearrival_jobs',{p_now:iso()});}
      else if(pluginKey==='restaurant_crm'&&row?.customer_id){result.result=await s.rpc(actionId==='refresh_metrics'?'anaira_refresh_restaurant_customer_360':'anaira_apply_restaurant_auto_tags',{p_tenant_id:tenantId,p_customer_id:row.customer_id});}
      else if(pluginKey==='lead_management'&&actionId==='convert_customer'){if(!row?.customer_id)throw new Error('Link this lead to a customer before conversion');const {data,error}=await s.from('crm_leads').update({stage:'converted'}).eq('id',row.id).eq('tenant_id',tenantId).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='loyalty'){if(!row?.customer_id)throw new Error('Select a loyalty account');if(actionId==='refresh_tier')result.result=await s.rpc('anaira_loyalty_post',{p_tenant_id:tenantId,p_customer_id:row.customer_id,p_domain:'crm',p_amount:0,p_reference_type:'tier_refresh',p_reference_id:row.id});else if(actionId==='redeem_reward'){if(!payload.rewardId)throw new Error('rewardId is required');result.result=await s.rpc('anaira_loyalty_redeem',{p_tenant_id:tenantId,p_customer_id:row.customer_id,p_reward_id:payload.rewardId,p_reference_id:row.id});}else if(actionId==='reverse_transaction'){const points=Number(payload.points);if(!Number.isFinite(points)||points<=0)throw new Error('Positive points required');result.result=await s.rpc('anaira_loyalty_post',{p_tenant_id:tenantId,p_customer_id:row.customer_id,p_domain:'crm',p_amount:0,p_reference_type:'reversal',p_reference_id:row.id});}else{const amount=Number(payload.amount);if(!Number.isFinite(amount)||amount<=0)throw new Error('Positive amount required');result.result=await s.rpc('anaira_loyalty_post',{p_tenant_id:tenantId,p_customer_id:row.customer_id,p_domain:'crm',p_amount:amount,p_reference_type:payload.referenceType||'plugin_action',p_reference_id:payload.referenceId||row.id});}}
      else if(pluginKey==='offers_coupons'&&actionId==='validate_coupon'){if(!row?.active)throw new Error('Coupon is inactive');const {count}=await s.from('crm_coupon_redemptions').select('id',{count:'exact',head:true}).eq('coupon_id',row.id);if(row.max_redemptions!=null&&Number(count||0)>=Number(row.max_redemptions))throw new Error('Redemption limit reached');result.result={valid:true,redemptions:count||0};}
      else if(pluginKey==='marketing_automation'&&actionId==='run_audience'){if(!row?.id)throw new Error('Select a campaign');const q=row.segment_id?s.from('crm_segment_members').select('customer_id').eq('segment_id',row.segment_id):s.from('crm_customers').select('id').eq('tenant_id',tenantId).limit(1000);const {data:members}=await q;const ids=(members||[]).map(x=>x.customer_id||x.id);for(const customerId of ids)await s.from('crm_campaign_recipients').upsert({campaign_id:row.id,customer_id:customerId,status:'queued'});await s.from('crm_campaigns').update({status:'audience_ready'}).eq('tenant_id',tenantId).eq('id',row.id);result.result={audienceSize:ids.length};}
      else if(pluginKey==='whatsapp_crm'&&actionId==='retry_failed'){if(!row?.id)throw new Error('Select a message');const {data,error}=await s.from('crm_message_log').update({status:'retry_queued'}).eq('tenant_id',tenantId).eq('id',row.id).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='segmentation'&&actionId==='activate_campaign'){if(!row?.id)throw new Error('Select a segment');const {data,error}=await s.from('crm_campaigns').insert({tenant_id:tenantId,property_id:row.property_id||payload.propertyId||null,name:`Segment Campaign - ${row.name}`,channel:'whatsapp',status:'draft',created_at:iso()}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='segmentation'){ if(!row?.id)throw new Error('Select a segment');const d=typeof row.definition==='string'?JSON.parse(row.definition):row.definition||{};let q=s.from('crm_customers').select('id,customer_type,vip,total_hotel_revenue,total_restaurant_revenue,total_restaurant_visits,property_id').eq('tenant_id',tenantId).eq(d.property_id ? 'property_id' : 'tenant_id', d.property_id || tenantId);if(d.customer_type)q=q.eq('customer_type',d.customer_type);if(d.vip!==undefined)q=q.eq('vip',!!d.vip);const {data:customers,error}=await q.limit(5000);if(error)throw error;const matched=(customers||[]).filter(x=>d.min_ltv?Number(x.total_hotel_revenue||0)+Number(x.total_restaurant_revenue||0)>=Number(d.min_ltv):true).filter(x=>d.min_visits?Number(x.total_restaurant_visits||0)>=Number(d.min_visits):true);await s.from('crm_segment_members').delete().eq('segment_id',row.id);if(matched.length)await s.from('crm_segment_members').insert(matched.map(x=>({segment_id:row.id,customer_id:x.id,calculated_at:iso(),reason:'definition-match',property_id:d.property_id||row.property_id||null})));result.result={matched:matched.length};}
      else if(pluginKey==='churn'&&actionId==='create_retention'){if(!row?.customer_id)throw new Error('Select a churn record');const {data,error}=await s.from('crm_followup_events').insert({tenant_id:tenantId,customer_id:row.customer_id,scheduled_at:new Date(Date.now()+86400000).toISOString(),status:'queued'}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='churn'&&row?.customer_id){result.result=await recomputeChurn(s,tenantId,row.customer_id,payload.propertyId||row?.property_id||null);}
      else if(pluginKey==='revenue_management'&&actionId==='generate_recommendation'){const roomTypeId=row?.room_type_id||payload.roomTypeId;if(!roomTypeId)throw new Error('roomTypeId is required');result.result=await s.rpc('anaira_generate_hotel_rate_recommendation',{p_tenant_id:tenantId,p_room_type_id:roomTypeId,p_stay_date:row?.stay_date||payload.stayDate||date()});}
      else if(pluginKey==='upselling'&&actionId==='find_eligible'){const {data:stays}=await s.from('crm_guest_stays').select('customer_id,check_in_date,check_out_date,booking_status').eq('tenant_id',tenantId).in('booking_status',['confirmed','checked_in','in_house']).limit(500);result.result={eligible:(stays||[]).length};}
      else if(pluginKey==='upselling'&&actionId==='send_offer'){if(!row?.id)throw new Error('Select an offer');const {data:stays}=await s.from('crm_guest_stays').select('customer_id').eq('tenant_id',tenantId).in('booking_status',['confirmed','checked_in','in_house']).limit(250);for(const x of stays||[])await s.from('crm_upsell_events').insert({tenant_id:tenantId,customer_id:x.customer_id,offer_id:row.id,reference_type:'upsell_offer',reference_id:row.id,status:'sent'});result.result={sentTo:(stays||[]).length};}
      else if(pluginKey==='cross_selling'&&actionId==='preview_matches'){const {count}=await s.from('crm_customers').select('id',{count:'exact',head:true}).eq('tenant_id',tenantId);result.result={matches:count||0};}
      else if(pluginKey==='cross_selling'&&actionId==='send_offers'){if(!row?.id)throw new Error('Select a rule');const {data:customers}=await s.from('crm_customers').select('id').eq('tenant_id',tenantId).limit(250);for(const c of customers||[])await s.from('crm_upsell_events').insert({tenant_id:tenantId,customer_id:c.id,offer_id:null,reference_type:'cross_sell_rule',reference_id:row.id,status:'sent'});result.result={sentTo:(customers||[]).length};}
      else if(pluginKey==='event_crm'&&actionId==='record_deposit'){const amount=Number(payload.amount);if(!row?.id||!Number.isFinite(amount)||amount<=0)throw new Error('Positive deposit amount required');await s.from('crm_timeline_events').insert({tenant_id:tenantId,customer_id:null,event_type:'event_deposit',source_system:'event_crm',source_id:row.id,title:`Deposit for ${row.name}`,description:`Deposit ₹${amount.toFixed(2)}`,amount});result.result={amount};}
      else if(pluginKey==='consent_privacy'&&actionId==='export_request'){const {data,error}=await s.from('crm_data_requests').insert({tenant_id:tenantId,customer_id:row?.customer_id||payload.customerId,request_type:'export',status:'queued',requested_at:iso()}).select().single();if(error)throw error;result.result=data;}
      else if(pluginKey==='relationship_manager'&&actionId==='rebalance'){
        const {data:active,error}=await s.from('crm_relationship_assignments').select('id,staff_id,customer_id').eq('tenant_id',tenantId).eq('active',true).order('assigned_at',{ascending:true}).limit(5000);
        if(error)throw error;
        const groups={}; for(const a of active||[]){const k=a.staff_id||'unassigned';(groups[k] ||= []).push(a);}
        const workload=Object.entries(groups).map(([staffId,items])=>({staffId,customers:items.length}));
        result.result={assignments:(active||[]).length,workload};
        await s.from('crm_notifications').insert({tenant_id:tenantId,notification_type:'relationship_rebalance',title:'Relationship portfolio rebalance analysed',body:`${(active||[]).length} active customer assignments analysed across ${workload.length} owners.`,severity:'info',action_url:'/relationship-manager'}).catch(()=>{});
      }
      else if(pluginKey==='advanced_analytics'&&actionId==='refresh_metrics'){result.result=await s.rpc('anaira_refresh_crm_analytics',{p_tenant_id:tenantId,p_metric_date:date()});}
      else if(pluginKey==='revenue_forecasting'&&(actionId==='generate_forecast'||actionId==='refresh_forecast')){const horizon=Math.max(1,Math.min(90,Number(payload.horizonDays||30)));const {data:m}=await s.from('crm_analytics_daily').select('hotel_revenue,restaurant_revenue').eq('tenant_id',tenantId).order('metric_date',{ascending:false}).limit(30);const base=(m||[]).reduce((a,x)=>a+Number(x.hotel_revenue||0)+Number(x.restaurant_revenue||0),0)/Math.max(1,(m||[]).length);const rows=Array.from({length:horizon},(_,i)=>({tenant_id:tenantId,property_id:payload.propertyId||null,forecast_date:new Date(Date.now()+(i+1)*86400000).toISOString().slice(0,10),horizon_days:horizon,occupancy_forecast:0,adr_forecast:0,revpar_forecast:Number(base.toFixed(2)),demand_index:base>0?1:0,confidence:.55,model_version:'moving-average-v1',factors:{baseline:Number(base.toFixed(2))}}));const {data,error}=await s.from('crm_revenue_forecasts').insert(rows).select();if(error)throw error;result.result={count:(data||[]).length,baseline:Number(base.toFixed(2))};}
      else if(pluginKey==='competitor_intelligence'&&actionId==='run_parity'){const {data:r}=await s.from('crm_competitor_rates').select('room_type_label,stay_date,rate').eq('tenant_id',tenantId).limit(1000);const vals=(r||[]).map(x=>Number(x.rate||0)).filter(Number.isFinite);result.result={samples:vals.length,median:vals.length?vals.sort((a,b)=>a-b)[Math.floor(vals.length/2)]:null};}
      else if(pluginKey==='competitor_intelligence'&&actionId==='normalize_rates'){const {data:rates}=await s.from('crm_competitor_rates').select('competitor_name,stay_date,room_type_label,rate').eq('tenant_id',tenantId).limit(1000);result.result={normalized:(rates||[]).length};}
      else if(pluginKey==='hotel-management-suite'&&actionId==='night_audit'){result.result=await s.rpc('anaira_night_audit',{p_restaurant_id:tenantId,p_business_date:date()});}
      else if(pluginKey==='hotel-booking'&&actionId==='check_availability'){const {data:r,error}=await s.from('hms_inventory').select('stay_date,room_type_id,total_rooms,sold_rooms,blocked_rooms,closed').eq('restaurant_id',tenantId).gte('stay_date',payload.checkIn||date()).lt('stay_date',payload.checkOut||date());if(error)throw error;result.result={available:(r||[]).filter(x=>!x.closed&&Number(x.total_rooms||0)-Number(x.sold_rooms||0)-Number(x.blocked_rooms||0)>0)};}
      else if(pluginKey==='hotel-booking'&&actionId==='create_hold'){if(!payload.roomTypeId||!payload.checkIn||!payload.checkOut)throw new Error('roomTypeId, checkIn and checkOut are required');result.result=await s.rpc('anaira_phase13_hotel_inventory_hold',{p_restaurant_id:tenantId,p_room_type_id:payload.roomTypeId,p_check_in:payload.checkIn,p_check_out:payload.checkOut,p_rooms:Number(payload.rooms||1),p_idempotency_key:payload.idempotencyKey||`plugin:${tenantId}:${Date.now()}`,p_reservation_id:null,p_ttl_minutes:Number(settings.inventory_hold_minutes||15)});}
      else if(pluginKey==='hotel-booking'&&(actionId==='confirm_booking'||actionId==='cancel_booking')){
        if(!row?.id)throw new Error('Select a booking transaction');
        if(actionId==='cancel_booking'){
          const {data,error}=await s.from('crm_booking_transactions').update({state:'cancelled',updated_at:iso()}).eq('tenant_id',tenantId).eq('id',row.id).select().single();
          if(error)throw error;
          if(row.booking_id) await s.from('hms_reservations').update({status:'cancelled',cancellation_reason:'Cancelled from Hotel Booking Engine',cancelled_at:iso(),updated_at:iso()}).eq('id',row.booking_id).eq('restaurant_id',tenantId);
          result.result=data;
        } else {
          const {data:dataTx,error:txErr}=await s.from('crm_booking_transactions').update({state:'confirmed',updated_at:iso()}).eq('tenant_id',tenantId).eq('id',row.id).select().single();
          if(txErr)throw txErr;
          if(row.booking_id){
            const {data:res,error:resErr}=await s.from('hms_reservations').update({status:'confirmed',updated_at:iso()}).eq('id',row.booking_id).eq('restaurant_id',tenantId).select().single();
            if(resErr)throw resErr;
            result.result={transaction:dataTx,reservation:res,payment_status:res.payment_status||'pending'};
          } else result.result=dataTx;
        }
      }
      else if(pluginKey==='anaira-pos'&&actionId==='sync_crm'){result.result=await s.rpc('anaira_refresh_global_customer_links',{p_tenant_id:tenantId,p_customer_id:payload.customerId||row?.customer_id});}
      else if(pluginKey==='channel-manager'&&actionId==='run_parity'){const {data:r}=await s.from('crm_channel_performance').select('channel,conversion_rate,revenue').eq('tenant_id',tenantId).limit(100);result.result={rows:r||[]};}
      else if(pluginKey==='seo-system'&&actionId==='generate_schema'){if(!row?.id)throw new Error('Select a SEO site');result.result=await callInternal(req,'/api/seo/schema',{siteId:row.id,type:payload.type||'WebPage',data:payload.data||{}});}
      else if(pluginKey==='omnichannel_timeline'&&actionId==='filter_source'){const source=payload.source;if(!row?.customer_id)throw new Error('Select a timeline event');let q=s.from('crm_timeline_events').select('*').eq('tenant_id',tenantId).eq('customer_id',row.customer_id);if(source)q=q.eq('source_system',source);const {data,error}=await q.order('occurred_at',{ascending:false}).limit(250);if(error)throw error;result.result=data||[];}
      else if(pluginKey==='advanced_analytics'&&actionId==='compare_periods'){const {data:r}=await s.from('crm_analytics_daily').select('*').eq('tenant_id',tenantId).order('metric_date',{ascending:false}).limit(62);result.result={rows:r||[]};}
      else if(pluginKey==='advanced_analytics'&&actionId==='open_cohorts'){const {data:r}=await s.from('crm_customer_value_snapshots').select('snapshot_date,calculated_ltv,visit_count').eq('tenant_id',tenantId).order('snapshot_date',{ascending:false}).limit(500);result.result={snapshots:r||[]};}
      else if(pluginKey==='revenue_forecasting'&&actionId==='compare_accuracy'){const {data:r}=await s.from('crm_revenue_forecasts').select('forecast_date,revpar_forecast,confidence,model_version').eq('tenant_id',tenantId).order('forecast_date',{ascending:false}).limit(100);result.result={count:(r||[]).length,models:[...new Set((r||[]).map(x=>x.model_version).filter(Boolean))]};}
      else if(pluginKey==='ai-review-system'&&actionId==='delivery_worker'){result.result=await callInternal(req,'/api/reviews/worker',{},true);}
      else throw new Error(`No derive handler for ${pluginKey}/${actionId}`);
      await audit(s,tenantId,user,def.dataTable,row?.id||null,actionId,null,result.result);return Response.json(result);
    }
    throw new Error(`Unsupported action kind: ${action.kind}`);
  }catch(e){return Response.json({ok:false,error:e.message},{status:400});}
}
