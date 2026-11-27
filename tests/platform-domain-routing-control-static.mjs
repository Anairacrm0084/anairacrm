import fs from 'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const proxy=read('proxy.js');
const adminApi=read('app/api/super-admin/platform-domains/route.js');
const publicApi=read('app/api/public/platform-domains/route.js');
const ui=read('app/super-admin/platform-domains/page.jsx');
const sidebar=read('app/components.js');
const resolver=read('app/api/public/property-store/resolve-domain/route.js');
const checks=[
 ['CRM domain is a protected platform hostname',/crm\.anairapos\.in/.test(adminApi)&&/crm\.anairapos\.in/.test(proxy)],
 ['Super Admin API validates authenticated super admin',/auth\.getUser\(token\)/.test(adminApi)&&/Super Admin access required/.test(adminApi)],
 ['Platform hostnames persist in existing platform settings',/anaira_platform_settings/.test(adminApi)&&/anaira_platform_hostnames/.test(adminApi)],
 ['Public proxy endpoint exposes hostnames only',/hostnames/.test(publicApi)&&!/service_role|secret/i.test(publicApi)],
 ['Proxy bypasses property resolver for configured platform hosts',/api\/public\/platform-domains/.test(proxy)&&/configuredHosts\.includes\(host\)/.test(proxy)],
 ['Default CRM and Anaira public marketplace hosts are protected',/anaira\.com/.test(publicApi)&&/www\.anaira\.com/.test(publicApi)],
 ['Super Admin navigation entry exists',/Platform Domain Routing/.test(sidebar)&&/super-admin\/platform-domains/.test(sidebar)],
 ['Domain routing page distinguishes app domains from property custom domains',/Application \/ Platform hostnames/.test(ui)&&/Property custom domains/.test(ui)],
 ['Custom property domain resolver remains verified and active gated',/domain_status.*active/.test(resolver)&&/verification_status.*verified/.test(resolver)],
 ['CRM domain is protected from accidental removal',/cannot remove/.test(ui)&&/DEFAULT_HOSTS/.test(adminApi)]
];
const failed=checks.filter(x=>!x[1]);
console.log(JSON.stringify({passed:checks.length-failed.length,total:checks.length,checks:checks.map(([name,ok])=>({name,ok})),failed:failed.map(x=>x[0])},null,2));
process.exitCode=failed.length?1:0;
