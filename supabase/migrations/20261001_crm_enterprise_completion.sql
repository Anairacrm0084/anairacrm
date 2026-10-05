-- ANAIRA CRM ENTERPRISE COMPLETION
-- UI/runtime completion companion migration. Reuses existing CRM data model.

-- Customer-channel records are tenant-scoped through the canonical customer.
alter table public.crm_customer_channels add column if not exists tenant_id uuid;
update public.crm_customer_channels c
set tenant_id = cu.tenant_id
from public.crm_customers cu
where cu.id = c.customer_id and c.tenant_id is null;
create index if not exists crm_customer_channels_tenant_idx on public.crm_customer_channels(tenant_id,customer_id,channel);

alter table public.crm_customer_channels enable row level security;
drop policy if exists customer_channels_auth on public.crm_customer_channels;
drop policy if exists crm_customer_channels_tenant on public.crm_customer_channels;
create policy crm_customer_channels_tenant on public.crm_customer_channels
for all to authenticated
using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));

-- Replace the original permissive CRM policies where the table has a direct tenant_id.
do $$
declare t text; p text;
begin
  foreach t in array array[
    'crm_loyalty_accounts','crm_rewards','crm_segments','crm_campaigns','crm_leads',
    'crm_corporate_accounts','crm_partners','crm_quotes','crm_followup_sequences','crm_followup_events',
    'crm_partner_bookings','crm_coupon_definitions','crm_coupon_redemptions','crm_referrals',
    'crm_service_recovery','crm_sla_rules','crm_relationship_assignments','crm_data_requests',
    'crm_ai_insights','crm_events','crm_upsell_offers','crm_upsell_events','crm_cross_sell_rules',
    'crm_review_requests','crm_customer_identity_links','crm_customer_merge_events','crm_opportunities',
    'crm_service_tickets','crm_service_ticket_events','crm_analytics_daily','crm_churn_scores','crm_vip_profiles'
  ] loop
    if to_regclass('public.'||t) is not null then
      for p in select policyname from pg_policies where schemaname='public' and tablename=t loop
        execute format('drop policy if exists %I on public.%I',p,t);
      end loop;
      execute format('create policy %I on public.%I for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id))',t||'_enterprise_tenant',t);
    end if;
  end loop;
end $$;

-- Tables without a direct tenant_id retain relationship-based access where required.
alter table public.crm_loyalty_transactions enable row level security;
drop policy if exists loyalty_transactions_authenticated on public.crm_loyalty_transactions;
drop policy if exists crm_loyalty_transactions_tenant on public.crm_loyalty_transactions;
create policy crm_loyalty_transactions_tenant on public.crm_loyalty_transactions
for all to authenticated
using (exists(select 1 from public.crm_loyalty_accounts a where a.id=loyalty_account_id and public.anaira_can_access_tenant(a.tenant_id)))
with check (exists(select 1 from public.crm_loyalty_accounts a where a.id=loyalty_account_id and public.anaira_can_access_tenant(a.tenant_id)));

-- Canonical CRM timeline writer for UI/API/worker integrations.
create or replace function public.anaira_record_crm_timeline(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_event_type text,
  p_source_system text,
  p_source_id text,
  p_title text,
  p_description text default null,
  p_amount numeric default null,
  p_metadata jsonb default '{}'::jsonb,
  p_occurred_at timestamptz default now()
) returns uuid
language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid;
begin
  if p_tenant_id is null or p_customer_id is null then raise exception 'tenant and customer are required'; end if;
  if not public.anaira_can_access_tenant(p_tenant_id) then raise exception 'tenant access denied'; end if;
  insert into public.crm_timeline_events(tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,metadata,occurred_at,created_at)
  values(p_tenant_id,p_customer_id,p_event_type,p_source_system,p_source_id,p_title,p_description,p_amount,coalesce(p_metadata,'{}'::jsonb),coalesce(p_occurred_at,now()),now())
  on conflict (tenant_id,source_system,source_id,event_type)
  do update set title=excluded.title,description=excluded.description,amount=excluded.amount,metadata=excluded.metadata,occurred_at=excluded.occurred_at
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.anaira_record_crm_timeline(uuid,uuid,text,text,text,text,text,numeric,jsonb,timestamptz) from public,anon;
grant execute on function public.anaira_record_crm_timeline(uuid,uuid,text,text,text,text,text,numeric,jsonb,timestamptz) to authenticated;

-- Operational indexes used by the completed CRM workspaces.
create index if not exists crm_customers_tenant_activity_idx on public.crm_customers(tenant_id,last_activity_at desc,updated_at desc);
create index if not exists crm_leads_tenant_stage_idx on public.crm_leads(tenant_id,stage,created_at desc);
create index if not exists crm_quotes_tenant_status_idx on public.crm_quotes(tenant_id,status,created_at desc);
create index if not exists crm_campaigns_tenant_status_idx on public.crm_campaigns(tenant_id,status,created_at desc);
create index if not exists crm_message_log_tenant_status_idx on public.crm_message_log(tenant_id,status,created_at desc);
create index if not exists crm_workflows_tenant_trigger_idx on public.crm_workflows(tenant_id,trigger_type,active);
create index if not exists crm_relationship_tenant_active_idx on public.crm_relationship_assignments(tenant_id,active,assigned_at desc);
create index if not exists crm_service_recovery_tenant_status_idx on public.crm_service_recovery(tenant_id,status,created_at desc);
create index if not exists crm_upsell_events_tenant_status_idx on public.crm_upsell_events(tenant_id,status,created_at desc);

