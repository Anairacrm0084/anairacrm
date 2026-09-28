-- ANAIRA P1 CRM MARKET PARITY
-- Real data model/runtime foundations for Customer 360, Sales CRM, Service CRM and Automation.

alter table public.crm_customers
  add column if not exists lifecycle_status text not null default 'active',
  add column if not exists merged_into_customer_id uuid references public.crm_customers(id) on delete set null,
  add column if not exists identity_confidence numeric(6,5),
  add column if not exists last_activity_at timestamptz;
create index if not exists crm_customers_merged_idx on public.crm_customers(tenant_id,merged_into_customer_id);

create table if not exists public.crm_customer_identity_links (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  source_type text not null,
  source_id text not null,
  match_key text,
  confidence numeric(6,5),
  verified boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id,source_type,source_id)
);

create table if not exists public.crm_sales_pipelines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  name text not null,
  pipeline_type text not null default 'sales',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_sales_stages (
  id uuid primary key default gen_random_uuid(),
  pipeline_id uuid not null references public.crm_sales_pipelines(id) on delete cascade,
  name text not null,
  position integer not null default 0,
  probability numeric(5,2) not null default 0,
  is_closed boolean not null default false,
  is_won boolean not null default false,
  created_at timestamptz not null default now(),
  unique(pipeline_id,position)
);

create table if not exists public.crm_opportunities (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  account_id uuid references public.crm_corporate_accounts(id) on delete set null,
  pipeline_id uuid references public.crm_sales_pipelines(id) on delete set null,
  stage_id uuid references public.crm_sales_stages(id) on delete set null,
  owner_id uuid,
  name text not null,
  value numeric(14,2) not null default 0,
  probability numeric(5,2) not null default 0,
  expected_close_at date,
  source text,
  status text not null default 'open',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crm_service_tickets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  customer_id uuid references public.crm_customers(id) on delete set null,
  subject text not null,
  description text,
  channel text not null default 'internal',
  priority text not null default 'normal',
  status text not null default 'open',
  assigned_to uuid,
  sla_due_at timestamptz,
  first_response_at timestamptz,
  resolved_at timestamptz,
  csat numeric(4,2),
  resolution text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crm_service_ticket_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  ticket_id uuid not null references public.crm_service_tickets(id) on delete cascade,
  event_type text not null,
  actor_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_workflow_action_definitions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  workflow_id uuid not null references public.crm_workflows(id) on delete cascade,
  action_index integer not null,
  action_type text not null,
  config jsonb not null default '{}'::jsonb,
  retry_policy jsonb not null default '{"max_attempts":3,"backoff_seconds":60}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(workflow_id,action_index)
);

create table if not exists public.crm_customer_merge_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  survivor_customer_id uuid not null references public.crm_customers(id) on delete cascade,
  merged_customer_id uuid not null references public.crm_customers(id) on delete cascade,
  reason text,
  evidence jsonb not null default '{}'::jsonb,
  actor_id uuid,
  created_at timestamptz not null default now()
);

create index if not exists crm_identity_customer_idx on public.crm_customer_identity_links(tenant_id,customer_id);
create index if not exists crm_pipeline_tenant_idx on public.crm_sales_pipelines(tenant_id,active);
create index if not exists crm_opportunity_tenant_stage_idx on public.crm_opportunities(tenant_id,status,stage_id,updated_at desc);
create index if not exists crm_ticket_tenant_status_idx on public.crm_service_tickets(tenant_id,status,priority,updated_at desc);
create index if not exists crm_ticket_customer_idx on public.crm_service_tickets(customer_id,created_at desc);
create index if not exists crm_ticket_events_idx on public.crm_service_ticket_events(ticket_id,created_at desc);
create index if not exists crm_workflow_actions_idx on public.crm_workflow_action_definitions(tenant_id,workflow_id,action_index);

alter table public.crm_customer_identity_links enable row level security;
alter table public.crm_sales_pipelines enable row level security;
alter table public.crm_sales_stages enable row level security;
alter table public.crm_opportunities enable row level security;
alter table public.crm_service_tickets enable row level security;
alter table public.crm_service_ticket_events enable row level security;
alter table public.crm_workflow_action_definitions enable row level security;
alter table public.crm_customer_merge_events enable row level security;

create policy crm_p1_identity_tenant on public.crm_customer_identity_links for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy crm_p1_pipeline_tenant on public.crm_sales_pipelines for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy crm_p1_stage_tenant on public.crm_sales_stages for all to authenticated using(exists(select 1 from public.crm_sales_pipelines p where p.id=pipeline_id and (p.tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()))) with check(exists(select 1 from public.crm_sales_pipelines p where p.id=pipeline_id and (p.tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())));
create policy crm_p1_opportunity_tenant on public.crm_opportunities for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy crm_p1_ticket_tenant on public.crm_service_tickets for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy crm_p1_ticket_event_tenant on public.crm_service_ticket_events for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy crm_p1_workflow_action_tenant on public.crm_workflow_action_definitions for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy crm_p1_merge_tenant on public.crm_customer_merge_events for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

-- Transaction-safe identity merge: keep the survivor as the canonical customer and retain an auditable link to the merged record.
create or replace function public.anaira_merge_crm_customer(p_survivor uuid,p_duplicate uuid,p_reason text default null,p_evidence jsonb default '{}')
returns jsonb language plpgsql security invoker set search_path=public,pg_temp as $$
declare s public.crm_customers; d public.crm_customers; tenant uuid;
begin
 if p_survivor is null or p_duplicate is null or p_survivor=p_duplicate then raise exception 'Invalid customer merge'; end if;
 select * into s from public.crm_customers where id=p_survivor for update;
 select * into d from public.crm_customers where id=p_duplicate for update;
 if not found or s.id is null or d.id is null then raise exception 'Customer not found'; end if;
 if d.merged_into_customer_id is not null then raise exception 'Duplicate customer is already merged'; end if;
 tenant:=coalesce(s.tenant_id,d.tenant_id);
 if s.tenant_id is distinct from d.tenant_id then raise exception 'Cross-tenant merge denied'; end if;
 update public.crm_customer_identity_links set customer_id=s.id,updated_at=now() where customer_id=d.id;
 update public.crm_customers set lifecycle_status='merged',merged_into_customer_id=s.id,updated_at=now() where id=d.id;
 update public.crm_customers set last_activity_at=greatest(coalesce(last_activity_at,'epoch'::timestamptz),coalesce(d.updated_at,'epoch'::timestamptz)),updated_at=now() where id=s.id;
 insert into public.crm_customer_merge_events(tenant_id,survivor_customer_id,merged_customer_id,reason,evidence,actor_id) values(tenant,s.id,d.id,p_reason,coalesce(p_evidence,'{}'),auth.uid());
 return jsonb_build_object('survivor_id',s.id,'merged_id',d.id,'status','merged');
end $$;

-- Customer 360 rollup from canonical CRM-owned facts. Operational records remain owned by their source systems.
create or replace function public.anaira_customer_360_summary(p_customer_id uuid)
returns jsonb language sql security invoker set search_path=public,pg_temp as $$
select jsonb_build_object(
 'customer',to_jsonb(c),
 'preferences',(select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) from crm_customer_preferences x where x.customer_id=c.id),
 'interactions',(select coalesce(jsonb_agg(to_jsonb(x) order by x.occurred_at desc),'[]'::jsonb) from crm_interactions x where x.customer_id=c.id limit 100),
 'tasks',(select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) from crm_tasks x where x.customer_id=c.id limit 100),
 'complaints',(select coalesce(jsonb_agg(to_jsonb(x) order by x.opened_at desc),'[]'::jsonb) from crm_complaints x where x.customer_id=c.id limit 100),
 'tickets',(select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) from crm_service_tickets x where x.customer_id=c.id limit 100),
 'opportunities',(select coalesce(jsonb_agg(to_jsonb(x) order by x.updated_at desc),'[]'::jsonb) from crm_opportunities x where x.customer_id=c.id limit 100)
) from crm_customers c where c.id=p_customer_id;
$$;
