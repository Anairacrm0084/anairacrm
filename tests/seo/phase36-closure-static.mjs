import fs from 'node:fs';import path from 'node:path';
const root=process.cwd();
const required=[
'app/api/seo/keyword-intelligence/route.js','app/api/seo/serp/visibility/route.js','app/api/seo/backlinks/gap/route.js','app/api/seo/geo/multi-model/route.js','app/api/seo/automation/graph/route.js'
];
for(const f of required)if(!fs.existsSync(path.join(root,f)))throw new Error(`Missing ${f}`);
const mp=fs.readFileSync(path.join(root,'lib/server/marketParity.js'),'utf8');
for(const token of ['keywordIntelligence','backlinkGap','serpVisibility','geoProviderRun'])if(!mp.includes(`export async function ${token}`))throw new Error(`Missing ${token}`);
const diag=fs.readFileSync(path.join(root,'app/api/seo/diagnostics/route.js'),'utf8');if(!diag.includes('BROWSERLESS_API_TOKEN'))throw new Error('Browserless diagnostics env contract is incorrect');
const rules=fs.readFileSync(path.join(root,'app/seo-review-utils.js'),'utf8');const n=(rules.match(/\['[^']+'/g)||[]).length;if(n<190)throw new Error(`technical rule registry unexpectedly low: ${n}`);
console.log(`Phase 36 SEO closure static: PASS; ${required.length} closure runtimes; technical registry ${n}`);
