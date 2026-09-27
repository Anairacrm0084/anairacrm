import fs from 'node:fs';
const required=['NEXT_PUBLIC_SUPABASE_URL','NEXT_PUBLIC_SUPABASE_ANON_KEY','SUPABASE_SERVICE_ROLE_KEY','ANAIRA_SECRET_KEY','CRON_SECRET','GOOGLE_CLIENT_ID','GOOGLE_CLIENT_SECRET','OPENAI_API_KEY','OPENAI_MODEL'];
const optional=['GOOGLE_PUBSUB_WEBHOOK_SECRET','WHATSAPP_ACCESS_TOKEN','WHATSAPP_PHONE_NUMBER_ID','TWILIO_ACCOUNT_SID','TWILIO_AUTH_TOKEN','TWILIO_FROM','RESEND_API_KEY','RESEND_FROM'];
const missing=required.filter(k=>!process.env[k]);
console.log(JSON.stringify({ok:missing.length===0,requiredMissing:missing,optionalConfigured:optional.filter(k=>Boolean(process.env[k])),next:'Deploy first, then run the real Google connect → discover → sync → AI → approve → publish E2E with a real authorized Business Profile.'},null,2));
process.exitCode=missing.length?1:0;
