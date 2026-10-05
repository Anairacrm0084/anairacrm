import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const cfg=JSON.parse(fs.readFileSync(path.join(root,'vercel.json'),'utf8'));
const required=['/api/distribution/sync/worker','/api/crm/campaign-worker','/api/crm/functional-worker','/api/crm/prearrival-worker','/api/reviews/worker','/api/seo/automation/worker','/api/seo/reports/worker'];
const routes=new Set((cfg.crons||[]).map(x=>x.path));
const missing=required.filter(x=>!routes.has(x));
if(missing.length){console.error('Missing cron routes:',missing.join(', '));process.exit(1)}
console.log(`Production scheduler: PASS (${required.length}/${required.length} workers scheduled)`);
