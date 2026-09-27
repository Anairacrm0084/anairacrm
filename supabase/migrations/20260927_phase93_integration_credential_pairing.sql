-- Separate the two machine credentials:
-- 1) restaurant_api_key authenticates CRM -> Restaurant SaaS.
-- 2) crm_callback_key authenticates Restaurant SaaS -> CRM webhooks.
alter table public.anaira_restaurant_connections
  add column if not exists crm_callback_key text,
  add column if not exists crm_callback_key_last4 text;
