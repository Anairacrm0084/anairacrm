import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const required = ['package.json', 'next.config.js', 'app', 'lib', 'docs', 'scripts'];
const envFiles = ['.env', '.env.local', '.env.production', '.env.production.local'];
const secretNames = new Set([
  'SUPABASE_SERVICE_ROLE_KEY','ANAIRA_SECRET_KEY','ANAIRA_SECRET','RESEND_API_KEY',
  'RAZORPAY_KEY_SECRET','RAZORPAY_WEBHOOK_SECRET','STRIPE_SECRET_KEY','STRIPE_WEBHOOK_SECRET',
  'OPENAI_API_KEY','GOOGLE_CLIENT_SECRET','TWILIO_AUTH_TOKEN','WHATSAPP_ACCESS_TOKEN',
  'CRON_SECRET','ANAIRA_PAYMENT_WEBHOOK_SECRET'
]);

const failures=[]; const warnings=[]; const checks=[];
const pass=(name,detail='')=>checks.push({name,status:'PASS',detail});
const warn=(name,detail='')=>{checks.push({name,status:'WARN',detail});warnings.push({name,detail});};
const fail=(name,detail='')=>{checks.push({name,status:'FAIL',detail});failures.push({name,detail});};

for (const p of required) fs.existsSync(path.join(root,p)) ? pass(`required:${p}`) : fail(`required:${p}`,'Missing required project path');

const pkg=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'));
for (const s of ['dev','build']) pkg.scripts?.[s] ? pass(`script:${s}`) : fail(`script:${s}`,'Missing npm script');

const files=[];
function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){if(['node_modules','.next','.git'].includes(e.name))continue;const f=path.join(dir,e.name);if(e.isDirectory())walk(f);else files.push(f);}}
walk(root);
const source=files.filter(f=>/\.(js|jsx|ts|tsx)$/.test(f));
const envRefs=new Set();
for(const f of source){const s=fs.readFileSync(f,'utf8'); for(const m of s.matchAll(/process\.env\.([A-Z0-9_]+)/g)) envRefs.add(m[1]);}
for(const name of envRefs){ if(secretNames.has(name) && files.some(f=>/\.env/.test(path.basename(f)))) warn(`secret-reference:${name}`,'Referenced by server source; verify it is never exposed via NEXT_PUBLIC_*'); }

for(const f of envFiles){if(!fs.existsSync(path.join(root,f)))continue;const content=fs.readFileSync(path.join(root,f),'utf8');for(const line of content.split(/\r?\n/)){const m=line.match(/^\s*([A-Z0-9_]+)\s*=/);if(m&&secretNames.has(m[1]))fail(`secret-file:${f}`,`Secret variable ${m[1]} must not be committed to the project archive`);}}

const result={project:pkg.name,phase:'P0',timestamp:new Date().toISOString(),summary:{failures:failures.length,warnings:warnings.length,checks:checks.length},checks,productionBuild:{status:'NOT_RUN',reason:'Dependency installation timed out in the clean environment; build must be rerun after dependencies are available.'},e2e:{status:'NOT_RUN',reason:'No live provider credentials/environment are available inside the source archive.'}};
fs.writeFileSync(path.join(root,'docs','P0_PRODUCTION_FOUNDATION_STATUS.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
process.exitCode=failures.length?1:0;
