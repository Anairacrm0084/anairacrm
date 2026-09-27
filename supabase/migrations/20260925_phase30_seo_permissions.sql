insert into public.anaira_permissions(permission_key,name,module,description) values
('seo-system.view','View SEO System','seo-system','View SEO analytics, audits and integrations'),
('seo-system.manage','Manage SEO System','seo-system','Run SEO operations and manage SEO records'),
('seo-system.configure','Configure SEO System','seo-system','Change SEO settings, providers and automation')
on conflict(permission_key) do update set name=excluded.name,module=excluded.module,description=excluded.description;
insert into public.anaira_role_permissions(role_key,permission_key)
select 'admin',p.permission_key from public.anaira_permissions p where p.permission_key in ('seo-system.view','seo-system.manage','seo-system.configure') on conflict do nothing;
insert into public.anaira_role_permissions(role_key,permission_key)
select 'manager',p.permission_key from public.anaira_permissions p where p.permission_key in ('seo-system.view','seo-system.manage') on conflict do nothing;
