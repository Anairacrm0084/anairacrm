import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const checks=[];
function file(p){return fs.existsSync(path.join(root,p))}
function text(p){return fs.readFileSync(path.join(root,p),'utf8')}
function check(name,ok,detail=''){checks.push({name,status:ok?'PASS':'FAIL',detail});}
check('runtime pricing migration',file('supabase/migrations/20261003_booking_engine_runtime_pricing_v3.sql'));
check('checkout uses v3 runtime transaction',text('app/book/[id]/checkout/page.js').includes("anaira_start_verified_hotel_booking_transaction_v3"));
check('checkout passes customer/corporate/negotiated context',/p_customer_id:form\.customerId[\s\S]*p_corporate_code:form\.corporateCode[\s\S]*p_negotiated_code:form\.negotiatedCode/.test(text('app/book/[id]/checkout/page.js')));
check('premium quote accepts runtime context',text('app/api/public/booking/premium/quote/route.js').includes('runtime_context'));
check('member context runtime function present',text('supabase/migrations/20261003_booking_engine_full_completion.sql').includes('anaira_booking_member_context'));
check('personalized offer runtime present',text('supabase/migrations/20261003_booking_engine_runtime_pricing_v3.sql').includes('booking_personalized_offers'));
check('corporate rate runtime present',text('supabase/migrations/20261003_booking_engine_runtime_pricing_v3.sql').includes('booking_corporate_rates'));
check('negotiated rate runtime present',text('supabase/migrations/20261003_booking_engine_runtime_pricing_v3.sql').includes('booking_negotiated_rates'));
check('direct benefits runtime present',text('supabase/migrations/20261003_booking_engine_runtime_pricing_v3.sql').includes('booking_direct_benefits'));
check('Razorpay signed webhook',text('app/api/payments/razorpay/webhook/route.js').includes('timingSafeEqual'));
check('Stripe signed webhook',text('app/api/payments/stripe/webhook/route.js').includes('timingSafeEqual'));
check('refund route',file('app/api/payments/refund/route.js'));
check('distribution webhook idempotency',text('app/api/distribution/webhook/[provider]/route.js').includes('idempotencyKey'));
check('distribution retry worker',text('app/api/distribution/sync/worker/route.js').includes('max_attempts'));
check('competitor rate storage',file('app/api/public/booking/parity/route.js') && text('app/api/public/booking/parity/route.js').includes('booking_rate_parity_snapshots'));
check('native OTA adapter module',file('lib/server/distribution/adapters/native.js'));
check('native OTA adapter dispatch',text('lib/server/distribution/runtime.js').includes('NATIVE_PROVIDER_CODES'));
check('competitor collector route',file('app/api/public/booking/parity/collect/route.js'));
check('A/B assignment route',file('app/api/public/booking/ab/route.js'));
check('group allocation + master folio route',file('app/api/public/booking/group/allocate/route.js'));
check('security closure migration',file('supabase/migrations/20261003_booking_engine_security_runtime_closure.sql'));
check('internal helper execution boundary',text('supabase/migrations/20261003_booking_engine_security_runtime_closure.sql').includes('revoke execute on function public.anaira_booking_member_context'));
check('checkout A/B assignment wiring',text('app/book/[id]/checkout/page.js').includes("/api/public/booking/ab"));
check('server-side booking start API',file('app/api/public/booking/start/route.js') && text('app/api/public/booking/start/route.js').includes('adminDb'));
check('privileged booking routes use service role',text('app/api/public/booking/ab/route.js').includes('adminDb') && text('app/api/public/booking/multi-room/route.js').includes('adminDb'));
check('final booking security migration',file('supabase/migrations/20261003_booking_engine_security_final.sql'));
check('hotel checkout uses canonical booking API',text('app/book/[id]/checkout/page.js').includes('/api/public/booking/start') && !text('app/book/[id]/checkout/page.js').includes('supabase.rpc(pricingRpc'));
check('camp checkout uses canonical booking API',text('app/camping/[id]/checkout/page.js').includes('/api/public/booking/start'));
check('stay checkout uses canonical booking API',text('app/stay/[type]/[id]/checkout/page.jsx').includes('/api/public/booking/start'));

const failures=checks.filter(x=>x.status==='FAIL');
console.log(JSON.stringify({phase:'booking-runtime-closure',status:failures.length?'FAIL':'PASS',checks:checks.length,failures},null,2));
process.exit(failures.length?1:0);
