import crypto from 'node:crypto';

function secretFrom(connection,platform){
  const ref=String(connection?.webhook_secret_ref||connection?.config?.webhook_secret_ref||platform?.config_schema?.webhook_secret_ref||'').trim();
  if(ref&&process.env[ref]) return process.env[ref];
  const code=String(platform?.provider_code||'').toUpperCase().replace(/[^A-Z0-9]/g,'_');
  return process.env[`ANAIRA_WEBHOOK_SECRET_${code}`]||null;
}

function header(req,name){return String(req.headers.get(name)||'').trim();}

export function verifyWebhookSignature(req,raw,{connection,platform}={}){
  const secret=secretFrom(connection,platform);
  if(!secret) return {ok:false,reason:'Webhook signing secret is not configured.'};
  const cfg=connection?.config||{};
  const signatureHeader=String(connection?.webhook_signature_header||cfg.webhook_signature_header||'x-webhook-signature');
  const supplied=header(req,signatureHeader)||header(req,'x-signature-256')||header(req,'x-hub-signature-256');
  if(!supplied) return {ok:false,reason:`Missing ${signatureHeader} header.`};
  const timestampHeader=String(connection?.webhook_timestamp_header||cfg.webhook_timestamp_header||'');
  const timestamp=timestampHeader?header(req,timestampHeader):'';
  const windowSeconds=Math.max(30,Number(connection?.webhook_replay_window_seconds||cfg.webhook_replay_window_seconds||300));
  if(timestamp){const ts=Number(timestamp);if(!Number.isFinite(ts)) return {ok:false,reason:'Invalid webhook timestamp.'};const ms=ts>1e12?ts:ts*1000;if(Math.abs(Date.now()-ms)>windowSeconds*1000)return {ok:false,reason:'Webhook timestamp outside replay window.'};}
  const algorithm=String(connection?.webhook_signature_algorithm||cfg.webhook_signature_algorithm||'sha256').toLowerCase();
  const digest=crypto.createHmac(algorithm,secret).update(timestamp?`${timestamp}.${raw}`:raw).digest('hex');
  const candidates=[supplied.replace(/^sha\d+=/i,'').trim(),supplied.replace(/^v\d+=/i,'').trim()].filter(Boolean);
  const valid=candidates.some(v=>{try{const a=Buffer.from(v,'hex');const b=Buffer.from(digest,'hex');return a.length===b.length&&crypto.timingSafeEqual(a,b)}catch{return false}});
  return valid?{ok:true}:{ok:false,reason:'Invalid webhook signature.'};
}
