import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const app=path.join(root,'app');
const routes=fs.readdirSync(app,{withFileTypes:true}).filter(x=>x.isDirectory() && fs.existsSync(path.join(app,x.name,'page.js'))).map(x=>x.name).sort();
const config=fs.readFileSync(path.join(app,'pageConfigs.js'),'utf8');
const keys=[...config.matchAll(/^'([^']+)':\{/gm)].map(m=>m[1]);
const dup=keys.filter((k,i)=>keys.indexOf(k)!==i);
const platformRoutes=new Set(['login','admin','plugins','booking','pms','reservation','delivery','store','channel-manager','pos','order','activity','guest-requests','housekeeping','import-export','my-permissions','my-work','partner-bookings','profile','quotes','team-tasks']);
const missing=[];
const imports=[];
function walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())walk(p);else if(e.name.endsWith('.js')){const s=fs.readFileSync(p,'utf8');for(const m of s.matchAll(/from ['"](\.\.?\/[^'"]+)['"]/g)){const q=path.resolve(path.dirname(p),m[1]);const candidates=[q,q+'.js',q+'.jsx',q+'.mjs',q+'.ts',q+'.tsx',path.join(q,'index.js'),path.join(q,'index.jsx'),path.join(q,'page.js'),path.join(q,'page.jsx')];if(!candidates.some(fs.existsSync)) imports.push(`${path.relative(root,p)} -> ${m[1]}`)}}}}
walk(app);
for(const required of ['components.js','ModulePage.js','pageConfigs.js','globals.css']) if(!fs.existsSync(path.join(app,required))) throw new Error(`Missing ${required}`);
if(dup.length||missing.length||imports.length) throw new Error(JSON.stringify({dup,missing,imports},null,2));
console.log(JSON.stringify({ok:true,routes:routes.length,configs:keys.length,unresolvedImports:0},null,2));
