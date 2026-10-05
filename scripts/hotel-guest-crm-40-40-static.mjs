import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const exists=p=>fs.existsSync(path.join(root,p));
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const checks=[];
const routeViews=['dashboard','guests','stays','lifecycle','pre-arrival','arrival','in-stay','post-stay','requests','complaints','preferences','upselling','cross-selling','feedback','communications','vip','loyalty','segments','retention','tasks','timeline','corporate','partners','documents','analytics','automation','ai','consent','integrations','audit','settings'];
for(const v of routeViews)checks.push([`route:${v}`,exists(v==='dashboard'?'app/hotel-guest-crm/page.js':`app/hotel-guest-crm/${v}/page.js`)]);
const c=read('app/hotel-guest-crm/_components/HotelGuestCRM.js');
const checksText=[
 ['live:supabase',c.includes("q('crm_customers'")&&c.includes("q('crm_guest_stays'")],
 ['manual:guest',c.includes("showForm==='guest'")],
 ['manual:stay',c.includes("showForm==='stay'")],
 ['manual:request',c.includes("showForm==='request'")],
 ['manual:complaint',c.includes("showForm==='complaint'")],
 ['manual:precheckin',c.includes("showForm==='precheckin'")],
 ['manual:preference',c.includes("showForm==='preference'")],
 ['manual:upsell',c.includes("showForm==='upsell'")],
 ['manual:crosssell',c.includes("showForm==='crossSell'")],
 ['manual:feedback',c.includes("showForm==='feedback'")],
 ['manual:task',c.includes("showForm==='task'")],
 ['manual:consent',c.includes("showForm==='consent'")],
 ['manual:corporate',c.includes("showForm==='corporate'")],
 ['manual:partner',c.includes("showForm==='partner'")],
 ['manual:document',c.includes("showForm==='document'")],
 ['manual:loyalty',c.includes("showForm==='loyalty'")],
 ['manual:vip',c.includes("showForm==='vip'")],
 ['manual:segment',c.includes("showForm==='segment'")],
 ['sync:booking',read('lib/server/hotel-guest-sync.js').includes("booking_reservations")&&read('lib/server/hotel-guest-sync.js').includes("customer_id:c.id")],
 ['sync:pms',read('lib/server/hotel-guest-sync.js').includes("pms_reservations")&&read('lib/server/hotel-guest-sync.js').includes("bookingCode")],
 ['security:permission',read('app/components.js').includes("hotel_guest_crm.view")&&c.includes("hotel_guest_crm.manage")],
 ['security:prearrival',read('app/api/crm/prearrival-worker/route.js').includes("requireTenant")],
 ['security:storage-delete',c.includes("storage.from('crm-guest-documents').remove")],
 ['security:signed-url',c.includes("createSignedUrl")],
 ['automation:tenant-worker',exists('app/api/crm/hotel-guest-automation/route.js')],
 ['automation:campaign-manual',exists('app/api/crm/campaign-worker-manual/route.js')],
 ['ai:execution',exists('app/api/crm/ai/execute/route.js')],
 ['timeline:canonical',c.includes("timelineEvents")&&c.includes("Unified Guest Timeline")],
 ['crosssell:route',exists('app/hotel-guest-crm/cross-selling/page.js')],
 ['crosssell:table',read('supabase/migrations/101_hotel_guest_crm_final_completion.sql').includes('crm_hotel_cross_sell_opportunities')],
 ['timeline:triggers',read('supabase/migrations/101_hotel_guest_crm_final_completion.sql').includes('anaira_hotel_guest_timeline_trigger')],
 ['rls:canonical',read('supabase/migrations/101_hotel_guest_crm_final_completion.sql').includes('crm_hgc_canonical_access')],
 ['booking-link',read('lib/server/hotel-guest-sync.js').includes("booking_reservations').update({customer_id:c.id")],
 ['consent-history',read('supabase/migrations/101_hotel_guest_crm_final_completion.sql').includes('crm_consent_events')],
 ['pos-timeline',read('supabase/migrations/101_hotel_guest_crm_final_completion.sql').includes('crm_restaurant_visits')],
 ['ltv',c.includes('crm_customer_value_snapshots')]
];
for(const x of checksText)checks.push(x);
const failed=checks.filter(x=>!x[1]);
console.log(JSON.stringify({total:checks.length,passed:checks.length-failed.length,failed:failed.map(x=>x[0])},null,2));
process.exitCode=failed.length?1:0;
