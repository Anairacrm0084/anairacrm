import fs from 'node:fs';
const root=process.cwd();
const required=['package.json','next.config.js','app/book/[id]/checkout/page.js','app/api/payments/razorpay/webhook/route.js','app/api/payments/stripe/webhook/route.js','app/api/distribution/webhook/[provider]/route.js','app/api/distribution/sync/worker/route.js','app/api/public/booking/parity/collect/route.js','app/api/public/booking/group/allocate/route.js'];
const missing=required.filter(p=>!fs.existsSync(`${root}/${p}`));
const env=['SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY','RAZORPAY_KEY_ID','RAZORPAY_KEY_SECRET','RAZORPAY_WEBHOOK_SECRET','STRIPE_SECRET_KEY','STRIPE_WEBHOOK_SECRET','RESEND_API_KEY','WHATSAPP_ACCESS_TOKEN'];
const configured=Object.fromEntries(env.map(k=>[k,Boolean(process.env[k])]));
console.log(JSON.stringify({source:{required:required.length,missing},providerEnvironment:configured,productionBuild:'requires dependency installation in deployment environment',browserE2E:'requires deployed URL + browser runtime',otaCertification:'requires provider-certified credentials/contracts',status:missing.length?'FAIL':'READY_FOR_ENVIRONMENT_CERTIFICATION'},null,2));
process.exit(missing.length?1:0);
