import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const requiredFiles=[
 'app/ai-reviews/page.js','lib/server/review-engine.js','lib/server/review-delivery.js','lib/server/review-config.js','lib/server/provider.js','lib/server/auth.js',
 'app/api/reviews/ai/route.js','app/api/reviews/approve/route.js','app/api/reviews/publish/route.js','app/api/reviews/process/route.js','app/api/reviews/sync/route.js','app/api/reviews/worker/route.js','app/api/reviews/webhook/google/route.js',
 'app/api/reviews/source/oauth/route.js','app/api/reviews/source/callback/route.js','app/api/reviews/source/discover/route.js','app/api/reviews/connection/route.js',
 'app/api/reviews/recovery/route.js','app/api/reviews/sla/route.js','app/api/reviews/automation/route.js','app/api/reviews/automation-rules/route.js','app/api/reviews/automation-rules/test/route.js',
 'app/api/reviews/templates/route.js','app/api/reviews/templates/history/route.js','app/api/reviews/templates/preview/route.js','app/api/reviews/templates/test/route.js',
 'app/api/reviews/analytics/route.js','app/api/reviews/analytics/export/route.js','app/api/reviews/retention/route.js','app/api/reviews/sources/route.js',
 'docs/AI_REVIEW_MASTER_COMPLETION_CHECKLIST.md','docs/AI_REVIEW_REAL_SETUP_STEPS.md'
];
const missing=requiredFiles.filter(f=>!fs.existsSync(path.join(root,f)));
const apiRoutes=[];function walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())walk(p);else if(e.name==='route.js'&&p.includes(`${path.sep}app${path.sep}api${path.sep}reviews${path.sep}`))apiRoutes.push(path.relative(root,p));}}walk(path.join(root,'app','api','reviews'));
const textFiles=[];function walkText(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())walkText(p);else if(/\.(js|jsx|md|json)$/.test(e.name))textFiles.push(p);}}walkText(path.join(root,'app'));walkText(path.join(root,'lib'));walkText(path.join(root,'docs'));
let placeholder=[];for(const f of textFiles){const t=fs.readFileSync(f,'utf8');if(/Coming Soon|under construction|TODO: IMPLEMENT|placeholder/i.test(t) && f.includes(`${path.sep}app${path.sep}api${path.sep}reviews`))placeholder.push(path.relative(root,f));}
const page=fs.readFileSync(path.join(root,'app/ai-reviews/page.js'),'utf8');
const checks={
  page:page.includes('Connect Google')&&page.includes('Automation Rule Builder')&&page.includes('Template Library')&&page.includes('Reputation Analytics'),
  oauth:fs.existsSync(path.join(root,'app/api/reviews/source/oauth/route.js'))&&fs.existsSync(path.join(root,'app/api/reviews/source/callback/route.js')),
  googleSync:fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('accounts/${accountId}/locations/${locationId}/reviews'),
  googleReply:fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('/reply'),
  automation:fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('executeAction')&&fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('runAutomation'),
  webhook:fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('processQueuedWebhookEvents'),
  aiGovernance:fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('crm_review_ai_runs')&&fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('json_schema'),
  retention:fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('retentionCleanup')&&fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('30*24*3600000'),
  disconnect:fs.readFileSync(path.join(root,'app/api/reviews/connection/route.js'),'utf8').includes('export async function DELETE'),
  recoveryLifecycle:fs.readFileSync(path.join(root,'app/api/reviews/recovery/route.js'),'utf8').includes("action='open'")&&fs.readFileSync(path.join(root,'app/api/reviews/recovery/route.js'),'utf8').includes('resolve')&&fs.readFileSync(path.join(root,'app/api/reviews/recovery/route.js'),'utf8').includes('close')
};
for(const [k,v] of Object.entries(checks)){if(!v){console.error(`FAIL:${k}`);process.exitCode=1;}}
if(missing.length){console.error('MISSING_FILES',missing);process.exitCode=1;}
if(placeholder.length){console.error('PLACEHOLDERS',placeholder);process.exitCode=1;}
console.log(JSON.stringify({ok:Object.values(checks).every(Boolean)&&!missing.length&&!placeholder.length,requiredFiles:requiredFiles.length,missing,reviewApiRoutes:apiRoutes.length,placeholder,checks},null,2));
