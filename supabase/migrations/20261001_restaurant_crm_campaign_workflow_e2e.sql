create unique index if not exists crm_campaign_recipients_campaign_customer_property_uidx on public.crm_campaign_recipients(campaign_id,customer_id,property_id);
create index if not exists crm_campaign_recipients_property_idx on public.crm_campaign_recipients(tenant_id,property_id,campaign_id,status);
create index if not exists crm_workflows_property_idx on public.crm_workflows(tenant_id,property_id,active);
create index if not exists crm_tasks_property_customer_idx on public.crm_tasks(tenant_id,property_id,customer_id,status);
