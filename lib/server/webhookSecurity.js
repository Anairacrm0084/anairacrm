import crypto from 'node:crypto';

const DEFAULT_TOLERANCE=300;

function firstHeader(headers,names){for(const n of names){const v=headers.get(n);if(v)return v.trim();}return '';}
function secretFor(connection,provider){
  const cfg=connection?.config&&typeof connection.config==='object'?connection.config:{};
  return String(cfg.webhook_secret||cfg.webhookSecret||process.env[`OTA_${String(provider).toUpperCase()}_WEBHOOK_SECRET`]||process.env[`ANAIRA_${String(provider).toUpperCase()}_WEBHOOK_SECRET`]||process.env.OTA_WEBHOOK_SECRET||'').trim();
}
function signatures(raw,secret,timestamp){
  const values=[
    crypto.createHmac('sha256',secret).update(raw).digest('hex'),
    crypto.createHmac('sha256',secret).update(`${timestamp}.${raw}`).digest('hex'),
    `sha256=${crypto.createHmac('sha256',secret).update(raw).digest('hex')}`,
    `sha256=${crypto.createHmac('sha256',secret).update(`${timestamp}.${raw}`).digest('hex')}`
  ];
  return values;
}
function safeEqual(a,b){const x=Buffer.from(String(a));const y=Buffer.from(String(b));return x.length===y.length&&crypto.timingSafeEqual(x,y);}

export function verifyDistributionWebhook({req,raw,provider,connection}){
  const secret=secretFor(connection,provider);
  if(!secret) throw Object.assign(new Error(`Webhook secret is not configured for ${provider}.`),{status:503});
  const signature=firstHeader(req.headers,['x-anaira-webhook-signature','x-webhook-signature','x-signature-256','x-signature']);
  if(!signature) throw Object.assign(new Error('Webhook signature is required.'),{status:401});
  const timestamp=firstHeader(req.headers,['x-anaira-webhook-timestamp','x-webhook-timestamp','x-timestamp']);
  const tolerance=Number(connection?.config?.webhook_timestamp_tolerance_seconds||process.env.OTA_WEBHOOK_TIMESTAMP_TOLERANCE_SECONDS||DEFAULT_TOLERANCE);
  if(timestamp){
    const ts=Number(timestamp);
    if(!Number.isFinite(ts)) throw Object.assign(new Error('Invalid webhook timestamp.'),{status:401});
    const seconds=Math.abs(Math.floor(Date.now()/1000)-Math.floor(ts));
    if(seconds>tolerance) throw Object.assign(new Error('Expired webhook timestamp.'),{status:401});
  }
  if(!signatures(raw,secret,timestamp).some(expected=>safeEqual(expected,signature))) throw Object.assign(new Error('Invalid webhook signature.'),{status:401});
  return {verified:true,timestamp:timestamp||null};
}
