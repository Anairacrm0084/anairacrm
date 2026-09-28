import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const required=[
 'supabase/migrations/20260928_phase_p2_hotel_booking_market_parity.sql',
 'app/api/hotel/payment/webhook/route.js',
 'app/api/payments/refund/route.js',
 'app/api/payments/razorpay/webhook/route.js',
 'app/api/payments/stripe/webhook/route.js'
];
const checks=[
 ['booking lifecycle ledger', 'anaira_booking_lifecycle_events'],
 ['transaction-safe cancellation RPC','anaira_cancel_hotel_booking'],
 ['modification ledger','anaira_booking_modification_requests'],
 ['transaction-safe modification RPC','anaira_request_hotel_booking_modification'],
 ['booking notification queue helper','anaira_queue_booking_notification'],
 ['confirmation notification trigger','trg_anaira_booking_confirmation_notify'],
 ['payment reconciliation view','anaira_hotel_payment_reconciliation'],
 ['refund runtime','anaira_request_payment_refund'],
 ['Razorpay signed webhook','RAZORPAY_WEBHOOK_SECRET'],
 ['Stripe signed webhook','STRIPE_WEBHOOK_SECRET']
];
let fail=[];
for(const f of required) if(!fs.existsSync(path.join(root,f))) fail.push(`missing:${f}`);
const sql=fs.readFileSync(path.join(root,required[0]),'utf8');
for(const [name,needle] of checks.slice(0,8)){ if(!sql.includes(needle) && !fs.readFileSync(path.join(root,'supabase/migrations/069_payment_runtime_and_queue_hardening.sql'),'utf8').includes(needle)) fail.push(`missing-check:${name}`); }
const routeFiles=required.slice(1).map(f=>fs.readFileSync(path.join(root,f),'utf8')).join('\n');
if(!routeFiles.includes('RAZORPAY_WEBHOOK_SECRET')) fail.push('razorpay signature contract');
if(!routeFiles.includes('STRIPE_WEBHOOK_SECRET')) fail.push('stripe signature contract');
console.log(JSON.stringify({phase:'P2',status:fail.length?'FAIL':'FOUNDATION',checks:checks.length-fail.length,failures:fail},null,2));
if(fail.length) process.exit(1);
