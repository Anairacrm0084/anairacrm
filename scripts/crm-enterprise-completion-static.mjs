import fs from 'node:fs';
const routes=['crm','customer-360','identity-resolution','leads','sales-pipeline','corporate','corporate-crm','partners','partner-crm','quotes','partner-bookings','guest-relations','complaints','loyalty','segments','segmentation','campaigns','marketing','whatsapp-crm','workflows','analytics','advanced-analytics','relationship-manager','ai','ai-crm','revenue','revenue-management','forecasting','revenue-forecasting','competitors','competitor-intelligence','timeline','omnichannel-timeline','consent-privacy','service-tickets','restaurant','events','vip','churn','upselling','cross-selling','reputation','customer-intelligence','customer-ltv','followups','guest-requests','service-recovery','offers-coupons'];
const checks=[];
checks.push(['enterprise component exists',fs.existsSync('app/CrmEnterprisePage.js')]);
checks.push(['enterprise migration exists',fs.existsSync('supabase/migrations/20261001_crm_enterprise_completion.sql')]);
for(const r of routes){const f=`app/${r}/page.js`;checks.push([`route ${r} exists`,fs.existsSync(f)]);if(fs.existsSync(f)){const s=fs.readFileSync(f,'utf8');checks.push([`route ${r} not generic`,!/(PluginPage|ModulePage|SimplePage)/.test(s)]);}}
const c=fs.readFileSync('app/components.js','utf8');
for(const x of ['/whatsapp-crm','/workflows','/campaigns','/offers-coupons','/service-recovery'])checks.push([`sidebar contains ${x}`,c.includes(x)]);
const bad=checks.filter(x=>!x[1]);console.log(JSON.stringify({total:checks.length,passed:checks.length-bad.length,failed:bad.map(x=>x[0])},null,2));process.exitCode=bad.length?1:0;
