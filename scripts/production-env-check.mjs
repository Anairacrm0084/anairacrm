import fs from 'node:fs';
const requiredForApp = ['NEXT_PUBLIC_SUPABASE_URL','NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY','SUPABASE_SERVICE_ROLE_KEY','ANAIRA_SECRET_KEY','CRON_SECRET'];
const providerGroups = {
  payments:['RAZORPAY_KEY_ID','RAZORPAY_KEY_SECRET','RAZORPAY_WEBHOOK_SECRET','STRIPE_SECRET_KEY','STRIPE_WEBHOOK_SECRET'],
  messaging:['WHATSAPP_ACCESS_TOKEN','WHATSAPP_PHONE_NUMBER_ID','RESEND_API_KEY','RESEND_FROM','TWILIO_ACCOUNT_SID','TWILIO_AUTH_TOKEN','TWILIO_FROM'],
  google:['GOOGLE_CLIENT_ID','GOOGLE_CLIENT_SECRET'],
  ai:['OPENAI_API_KEY'],
  seo:['DATAFORSEO_LOGIN','DATAFORSEO_PASSWORD','SERPAPI_KEY']
};
const check=k=>Boolean(process.env[k]);
const result={generated_at:new Date().toISOString(),requiredForApp:Object.fromEntries(requiredForApp.map(k=>[k,check(k)])),providers:Object.fromEntries(Object.entries(providerGroups).map(([g,keys])=>[g,Object.fromEntries(keys.map(k=>[k,check(k)]))])),packageLock:fs.existsSync('package-lock.json')};
result.readyForProduction = result.packageLock && Object.values(result.requiredForApp).every(Boolean);
console.log(JSON.stringify(result,null,2));
process.exitCode = result.readyForProduction ? 0 : 2;
