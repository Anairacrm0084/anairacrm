-- CRM full function closure: schema support for real domain lifecycles
alter table public.crm_complaints add column if not exists assigned_to uuid;

alter table public.crm_loyalty_transactions add column if not exists idempotency_key text;
create unique index if not exists crm_loyalty_tx_idempotency_uidx
on public.crm_loyalty_transactions(tenant_id,idempotency_key)
where idempotency_key is not null;

create table if not exists public.crm_campaign_attribution (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 campaign_id uuid not null, customer_id uuid, recipient_id uuid, event_type text not null,
 revenue numeric(14,2) not null default 0, reference_type text, reference_id text,
 occurred_at timestamptz not null default now(), created_at timestamptz not null default now()
);
create index if not exists crm_campaign_attr_scope_idx on public.crm_campaign_attribution(tenant_id,property_id,campaign_id,occurred_at desc);
alter table public.crm_campaign_attribution enable row level security;
drop policy if exists crm_campaign_attr_tenant on public.crm_campaign_attribution;
create policy crm_campaign_attr_tenant on public.crm_campaign_attribution for all to authenticated
using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_event_transactions (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 event_id uuid not null, transaction_type text not null, amount numeric(14,2) not null default 0,
 payment_reference text, status text not null default 'pending', notes text, created_by uuid,
 created_at timestamptz not null default now()
);
create index if not exists crm_event_tx_scope_idx on public.crm_event_transactions(tenant_id,property_id,event_id,created_at desc);
alter table public.crm_event_transactions enable row level security;
drop policy if exists crm_event_tx_tenant on public.crm_event_transactions;
create policy crm_event_tx_tenant on public.crm_event_transactions for all to authenticated
using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_rate_decisions (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 forecast_id uuid, room_type_id uuid, rate_plan_id uuid, decision_type text not null,
 old_rate numeric(14,2), recommended_rate numeric(14,2), published_rate numeric(14,2),
 rationale jsonb not null default '{}'::jsonb, status text not null default 'draft',
 approved_by uuid, approved_at timestamptz, published_at timestamptz, created_at timestamptz not null default now()
);
create index if not exists crm_rate_decisions_scope_idx on public.crm_rate_decisions(tenant_id,property_id,created_at desc);
alter table public.crm_rate_decisions enable row level security;
drop policy if exists crm_rate_decisions_tenant on public.crm_rate_decisions;
create policy crm_rate_decisions_tenant on public.crm_rate_decisions for all to authenticated
using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_relationship_workload_history (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 staff_id uuid, before_count integer not null default 0, after_count integer not null default 0,
 action text not null, created_at timestamptz not null default now()
);
create index if not exists crm_relationship_workload_scope_idx on public.crm_relationship_workload_history(tenant_id,property_id,created_at desc);
alter table public.crm_relationship_workload_history enable row level security;
drop policy if exists crm_relationship_workload_tenant on public.crm_relationship_workload_history;
create policy crm_relationship_workload_tenant on public.crm_relationship_workload_history for all to authenticated
using (anaira_can_access_tenant(tenant_id)) with check (anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_crm_record_action(
 p_tenant_id uuid,p_property_id uuid,p_entity_type text,p_entity_id uuid,p_action text,p_payload jsonb default '{}'::jsonb
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null or not anaira_can_access_tenant(p_tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;
 insert into public.crm_audit_logs(tenant_id,property_id,actor_id,entity_type,entity_id,action,before_data,after_data)
 values(p_tenant_id,p_property_id,auth.uid(),p_entity_type,p_entity_id,p_action,null,coalesce(p_payload,'{}'::jsonb));
 return jsonb_build_object('ok',true,'action',p_action,'entity_id',p_entity_id);
end $$;
revoke all on function public.anaira_crm_record_action(uuid,uuid,text,uuid,text,jsonb) from public,anon;
grant execute on function public.anaira_crm_record_action(uuid,uuid,text,uuid,text,jsonb) to authenticated;
