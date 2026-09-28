import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url); const ts=require('/opt/nvm/versions/node/v22.16.0/lib/node_modules/typescript/lib/typescript.js');
const root=process.cwd();
const files=['app/store/page.js','app/store-builder/page.js','app/platform-store-control.js','app/super-admin/marketplace-settings/page.jsx','app/anaira/food/page.jsx'];
const required=['supabase/migrations/20260928_restaurant_marketplace_pro_home.sql'];
const checks=[
 ['Restaurant marketplace route',fs.existsSync(path.join(root,'app/store/page.js'))],
 ['Restaurant marketplace redirect',fs.existsSync(path.join(root,'app/anaira/food/page.jsx'))],
 ['Super Admin marketplace control',fs.existsSync(path.join(root,'app/super-admin/marketplace/page.jsx'))],
 ['Restaurant banner migration',fs.existsSync(path.join(root,required[0]))],
 ['Featured item presentation table',fs.readFileSync(path.join(root,required[0]),'utf8').includes('anaira_marketplace_featured_items')],
 ['Banner presentation table',fs.readFileSync(path.join(root,required[0]),'utf8').includes('anaira_store_banners')],
 ['Live Restaurant SaaS bridge',fs.readFileSync(path.join(root,'app/store/page.js'),'utf8').includes('/api/marketplace/restaurant/')],
 ['Popular dishes section',fs.readFileSync(path.join(root,'app/store/page.js'),'utf8').includes('POPULAR DISHES')],
 ['Admin banner settings',fs.readFileSync(path.join(root,'app/store-builder/page.js'),'utf8').includes('Restaurant Marketplace Homepage')],
 ['Admin featured dish settings',fs.readFileSync(path.join(root,'app/store-builder/page.js'),'utf8').includes('toggleFeatured')],
 ['Super Admin global banners',fs.readFileSync(path.join(root,'app/super-admin/marketplace-settings/page.jsx'),'utf8').includes('Restaurant Marketplace Home')],
 ['Responsive marketplace CSS',fs.readFileSync(path.join(root,'app/globals.css'),'utf8').includes('.food-marketplace')],
];
let bad=0;
for(const f of files){const file=path.join(root,f);const src=fs.readFileSync(file,'utf8');const out=ts.transpileModule(src,{compilerOptions:{jsx:ts.JsxEmit.ReactJSX,target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.ESNext},reportDiagnostics:true});const errors=(out.diagnostics||[]).filter(d=>d.category===ts.DiagnosticCategory.Error);if(errors.length){bad++;console.error('SYNTAX FAIL',f,errors.map(e=>ts.flattenDiagnosticMessageText(e.messageText,' ')).join('; '))}else console.log('SYNTAX PASS',f)}
for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)bad++}
if(bad)process.exit(1);console.log(`Restaurant Marketplace PRO static checks PASS: ${checks.length}/${checks.length}`);
