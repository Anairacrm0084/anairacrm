import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const checks=[
 ['master checklist exists', fs.existsSync(path.join(root,'docs/AI_REVIEW_MASTER_COMPLETION_CHECKLIST.md'))],
 ['AI run ledger migration', fs.readFileSync(path.join(root,'supabase/migrations/20260925_phase26_ai_review_master_completion.sql'),'utf8').includes('crm_review_ai_runs')],
 ['provider action idempotency', fs.readFileSync(path.join(root,'supabase/migrations/20260925_phase26_ai_review_master_completion.sql'),'utf8').includes('crm_review_provider_actions_idempotency_uq')],
 ['webhook dedupe', fs.readFileSync(path.join(root,'supabase/migrations/20260925_phase26_ai_review_master_completion.sql'),'utf8').includes('unique(provider,event_key)')],
 ['structured AI schema', fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('json_schema')],
 ['AI telemetry', fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('crm_review_ai_runs')],
 ['Google publish audit', fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('providerAudit')],
 ['explicit auto-publish consent', fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes('reply_automation_consent===true')],
 ['recovery idempotency', fs.readFileSync(path.join(root,'lib/server/review-engine.js'),'utf8').includes("in('status',['open','in_progress'])")],
 ['delivery retry/dead letter', fs.readFileSync(path.join(root,'app/api/reviews/worker/route.js'),'utf8').includes("'dead_letter'")],
 ['retention cleanup', fs.readFileSync(path.join(root,'app/api/reviews/retention/route.js'),'utf8').includes('retentionCleanup')],
 ['approval route uses authenticated tenant', fs.readFileSync(path.join(root,'app/api/reviews/approve/route.js'),'utf8').includes('requireTenant') && fs.readFileSync(path.join(root,'app/api/reviews/approve/route.js'),'utf8').includes('auditReview')],
 ['publish route uses engine', fs.readFileSync(path.join(root,'app/api/reviews/publish/route.js'),'utf8').includes('publishGoogleReply')],
 ['AI route uses engine', fs.readFileSync(path.join(root,'app/api/reviews/ai/route.js'),'utf8').includes('classifyReview')],
 ['recovery route uses engine', fs.readFileSync(path.join(root,'app/api/reviews/recovery/route.js'),'utf8').includes('ensureRecovery')],
];
let pass=0;for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(ok)pass++;}
console.log(`P4 static checks: ${pass}/${checks.length} PASS`);process.exitCode=pass===checks.length?0:1;
