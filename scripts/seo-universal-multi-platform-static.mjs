import fs from 'node:fs'; import path from 'node:path';
const root=process.cwd();
const required=['lib/server/seoBusiness.js','app/api/seo/business-profile/route.js','supabase/migrations/20261004_seo_universal_business_platform.sql'];
for(const f of required) if(!fs.existsSync(path.join(root,f))) throw new Error(`Missing ${f}`);
const b=fs.readFileSync(path.join(root,required[0]),'utf8');
for(const token of ['barber_shop','clinic','professional_services','retail','ecommerce','saas','local_service','SEO_PLATFORM_TYPES','SEO_GOALS','SEO_ENTITY_TYPES']) if(!b.includes(token)) throw new Error(`Missing universal SEO capability ${token}`);
const r=fs.readFileSync(path.join(root,required[1]),'utf8'); for(const token of ['business_vertical','platform_type','seo_profile','SEO_BUSINESS_VERTICALS','SEO_PLATFORM_TYPES']) if(!r.includes(token)) throw new Error(`Missing API contract ${token}`);
const sql=fs.readFileSync(path.join(root,required[2]),'utf8'); for(const token of ['business_vertical','platform_type','seo_profile']) if(!sql.includes(`add column if not exists ${token}`)) throw new Error(`Missing DB column ${token}`);
console.log('Universal multi-business / multi-platform SEO static contract: 10/10 PASS');
