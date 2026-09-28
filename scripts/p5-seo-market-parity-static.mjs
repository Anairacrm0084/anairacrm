import fs from 'node:fs';import path from 'node:path';
const checks=[
 ['migration','supabase/migrations/20260928_phase_p5_seo_market_parity.sql'],
 ['web index API','app/api/seo/web-index/route.js'],['SERP API','app/api/seo/serp/route.js'],['local grid API','app/api/seo/local/grid/route.js'],['GEO API','app/api/seo/geo/route.js'],['attribution API','app/api/seo/attribution/route.js'],
 ['crawl runtime','app/api/seo/crawl/route.js'],['SEO engine','lib/server/seoEngine.js'],['technical registry','app/seo-review-utils.js'],['SEO runtime auth','lib/server/seoRuntime.js']
];
let pass=0;for(const [name,file] of checks){if(!fs.existsSync(file))throw new Error(`FAIL ${name}: ${file}`);const s=fs.readFileSync(file,'utf8');if(!s.trim())throw new Error(`FAIL ${name}: empty`);console.log(`PASS ${name}`);pass++}
const migration=fs.readFileSync(checks[0][1],'utf8');for(const token of ['anaira_seo_web_pages','anaira_seo_web_links','anaira_seo_serp_snapshots','anaira_seo_backlink_snapshots','anaira_seo_local_grid_runs','anaira_seo_geo_runs','anaira_seo_attribution_events','row level security']){if(!migration.toLowerCase().includes(token.toLowerCase()))throw new Error(`FAIL migration token ${token}`)}
const pkg=JSON.parse(fs.readFileSync('package.json','utf8'));if(pkg.scripts['p5:check']!=='node scripts/p5-seo-market-parity-static.mjs')throw new Error('FAIL package script');
console.log(`P5 static checks ${pass+2}/${pass+2} PASS`);
