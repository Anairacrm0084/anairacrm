-- Register Phase 17 SEO + AI Review plugins in the platform catalog.
insert into public.anaira_plugin_catalog(plugin_key,display_name,category,description,route,core) values
('seo-system','Anaira SEO System','CRM/Marketing','Technical SEO, crawler, audits, keywords, schema, sitemap, Search Console and AI content optimization.','/seo',false),
('ai-review-system','Anaira AI Review Automation','CRM/Reputation','Review requests, source sync, AI sentiment, reply drafting, approvals, service recovery and reputation analytics.','/ai-reviews',false)
on conflict(plugin_key) do update set display_name=excluded.display_name,category=excluded.category,description=excluded.description,route=excluded.route,core=excluded.core;
