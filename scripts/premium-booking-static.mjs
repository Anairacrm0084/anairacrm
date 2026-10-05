import fs from 'node:fs'; import path from 'node:path';
const root=process.cwd(); const req=[
'supabase/migrations/20261003_booking_engine_premium_closure.sql',
'app/api/public/booking/premium/quote/route.js',
'app/api/public/booking/manage/route.js',
'app/api/public/booking/events/route.js',
'app/api/public/booking/group/route.js',
'app/api/public/booking/multi-room/route.js',
'app/api/public/booking/parity/route.js',
'app/manage-booking/page.js','app/group-booking/page.js'
]; const needles=['anaira_calculate_hotel_premium_quote','anaira_start_verified_hotel_booking_transaction_v2','anaira_create_multi_room_booking_transaction','anaira_public_booking_lookup','booking_conversion_events','booking_abandoned_sessions','booking_rate_parity_snapshots','booking_group_requests','booking_member_rates']; let fail=[]; for(const f of req) if(!fs.existsSync(path.join(root,f))) fail.push('missing:'+f); const sql=fs.readFileSync(path.join(root,req[0]),'utf8'); for(const n of needles) if(!sql.includes(n)) fail.push('missing:'+n); const checkout=fs.readFileSync(path.join(root,'app/book/[id]/checkout/page.js'),'utf8'); for(const n of ['/api/public/booking/premium/quote','couponApplied','selectedAddons']) if(!checkout.includes(n)) fail.push('checkout:'+n); console.log(JSON.stringify({phase:'premium-booking',status:fail.length?'FAIL':'PASS',checks:req.length+needles.length+3,failures:fail},null,2)); if(fail.length)process.exit(1);
