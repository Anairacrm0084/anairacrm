-- CRM A-to-Z property scope completion
-- Adds explicit property context to operational CRM records without rebuilding the CRM model.
create table if not exists public.crm_property_record_scope (
  tenant_id uuid not null,
  property_id uuid not null references public.anaira_hospitality_properties_master(id) on delete cascade,
  table_name text not null,
  record_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (property_id, table_name, record_id)
);
create index if not exists crm_property_record_scope_tenant_idx on public.crm_property_record_scope(tenant_id, property_id, table_name);
alter table public.crm_property_record_scope enable row level security;
drop policy if exists crm_property_record_scope_access on public.crm_property_record_scope;
create policy crm_property_record_scope_access on public.crm_property_record_scope for all using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));

-- Missing operational tables used by the enterprise CRM runtime.
create table if not exists public.crm_customer_identity_links (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 customer_id uuid, duplicate_customer_id uuid, source_type text, source_id text,
 match_key text, confidence numeric(5,4), verified boolean default false,
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists public.crm_opportunities (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 customer_id uuid, lead_id uuid, name text not null, value numeric(14,2) default 0,
 probability numeric(5,2) default 0, expected_close_at timestamptz, source text,
 status text default 'open', notes text, created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists public.crm_service_tickets (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 customer_id uuid, subject text not null, channel text, priority text default 'normal',
 status text default 'open', assigned_to uuid, sla_due_at timestamptz, csat numeric(4,2),
 resolution text, created_at timestamptz default now(), updated_at timestamptz default now()
);

-- Operational CRM tables exposed by the dedicated enterprise pages.
do $$
declare t text;
begin
 foreach t in array array[
 'crm_customers','crm_customer_identity_links','crm_leads','crm_opportunities','crm_corporate_accounts','crm_partners',
 'crm_quotes','crm_partner_bookings','crm_complaints','crm_loyalty_accounts','crm_segments','crm_coupon_definitions',
 'crm_campaigns','crm_message_log','crm_workflows','crm_analytics_daily','crm_relationship_assignments','crm_ai_insights',
 'crm_revenue_forecasts','crm_competitor_rates','crm_timeline_events','crm_consents','crm_service_tickets','crm_restaurant_visits',
 'crm_events','crm_churn_scores','crm_upsell_events','crm_hotel_cross_sell_opportunities','crm_reviews',
 'crm_audit_logs','crm_followup_events','crm_notifications','crm_partner_settlements','crm_data_requests',
 'crm_message_templates','crm_campaign_steps','crm_vip_profiles','crm_service_recovery','crm_loyalty_transactions','crm_customer_channels'
 ] loop
  if exists(select 1 from information_schema.tables where table_schema='public' and table_name=t) then
    if not exists(select 1 from information_schema.columns where table_schema='public' and table_name=t and column_name='tenant_id') then
      execute format('alter table public.%I add column tenant_id uuid',t);
    end if;
    if not exists(select 1 from information_schema.columns where table_schema='public' and table_name=t and column_name='property_id') then
      execute format('alter table public.%I add column property_id uuid',t);
    end if;
    execute format('create index if not exists %I on public.%I(tenant_id,property_id)',left(t||'_tenant_property_idx',63),t);
  end if;
 end loop;
end $$;

alter table public.crm_customer_identity_links enable row level security;
alter table public.crm_opportunities enable row level security;
alter table public.crm_service_tickets enable row level security;
do $$ begin
 create policy crm_customer_identity_links_access on public.crm_customer_identity_links for all using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));
exception when duplicate_object then null; end $$;
do $$ begin
 create policy crm_opportunities_access on public.crm_opportunities for all using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));
exception when duplicate_object then null; end $$;
do $$ begin
 create policy crm_service_tickets_access on public.crm_service_tickets for all using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));
exception when duplicate_object then null; end $$;

-- Safe backfill only when a tenant has exactly one active hospitality property.
do $$
declare t text;
begin
 foreach t in array array[
 'crm_customers','crm_customer_identity_links','crm_leads','crm_opportunities','crm_corporate_accounts','crm_partners',
 'crm_quotes','crm_partner_bookings','crm_complaints','crm_loyalty_accounts','crm_segments','crm_coupon_definitions',
 'crm_campaigns','crm_message_log','crm_workflows','crm_analytics_daily','crm_relationship_assignments','crm_ai_insights',
 'crm_revenue_forecasts','crm_competitor_rates','crm_timeline_events','crm_consents','crm_service_tickets','crm_restaurant_visits',
 'crm_events','crm_churn_scores','crm_upsell_events','crm_hotel_cross_sell_opportunities','crm_reviews'
 ] loop
  if exists(select 1 from information_schema.tables where table_schema='public' and table_name=t) then
    execute format($q$
      update public.%I x
      set tenant_id=coalesce(x.tenant_id,p.tenant_id), property_id=coalesce(x.property_id,p.id)
      from (select tenant_id,min(id::text)::uuid id from public.anaira_hospitality_properties_master where active=true group by tenant_id having count(*)=1) p
      where x.tenant_id=p.tenant_id and x.property_id is null
    $q$,t);
  end if;
 end loop;
end $$;

insert into public.crm_property_record_scope(tenant_id,property_id,table_name,record_id)
select tenant_id,property_id,'crm_customers',id from public.crm_customers
where tenant_id is not null and property_id is not null on conflict do nothing;
