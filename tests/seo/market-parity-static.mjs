import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const required=[
 'supabase/migrations/20260926_phase32_market_parity_engine.sql',
 'lib/server/marketParity.js',
 'app/api/seo/market-parity/route.js'
];
for(const f of required){if(!fs.existsSync(path.join(root,f)))throw new Error(`Missing ${f}`)}
const sql=fs.readFileSync(path.join(root,required[0]),'utf8');
for(const t of ['crm_seo_web_index_pages','crm_seo_keyword_index','crm_seo_serp_index','crm_seo_backlink_index','crm_seo_local_grid_runs','crm_seo_competitor_intelligence','crm_seo_content_scores','crm_seo_provider_telemetry','crm_seo_revenue_attribution','crm_seo_market_certification'])if(!sql.includes(`create table if not exists public.${t}`))throw new Error(`Missing table ${t}`);
const lib=fs.readFileSync(path.join(root,required[1]),'utf8');
for(const token of ['capabilityCatalog','providerFetch','keywordResearch','serpSnapshot','contentScore','certificationSummary'])if(!lib.includes(token))throw new Error(`Missing engine capability ${token}`);
console.log('Market parity static contract: PASS');
