-- Phase 38: CRM workflow queue + tenant security hardening
alter table public.crm_workflows enable row level security;
alter table public.crm_workflow_runs enable row level security;
alter table public.crm_notifications enable row level security;

drop policy if exists workflows_auth on public.crm_workflows;
drop policy if exists workflow_runs_auth on public.crm_workflow_runs;
drop policy if exists notifications_auth on public.crm_notifications;

create policy workflows_tenant_access on public.crm_workflows
for all to authenticated
using (tenant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (tenant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

create policy workflow_runs_tenant_access on public.crm_workflow_runs
for all to authenticated
using (tenant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (tenant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

create policy notifications_tenant_access on public.crm_notifications
for all to authenticated
using (tenant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (tenant_id = public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

create index if not exists crm_workflows_tenant_active_idx on public.crm_workflows(tenant_id, active);
create index if not exists crm_workflow_runs_tenant_status_idx on public.crm_workflow_runs(tenant_id, status, started_at);
create index if not exists crm_notifications_tenant_created_idx on public.crm_notifications(tenant_id, created_at desc);
create index if not exists crm_workflow_queue_claim_idx on public.crm_workflow_queue(status, available_at, tenant_id);

create or replace function public.anaira_claim_workflow_jobs(p_tenant_id uuid default null, p_limit int default 20)
returns setof public.crm_workflow_queue
language sql security invoker
set search_path = public, pg_temp
as $$
with c as (
  select id
  from public.crm_workflow_queue
  where status = 'queued'
    and available_at <= now()
    and (p_tenant_id is null or tenant_id = p_tenant_id)
  order by available_at, id
  for update skip locked
  limit greatest(1, least(p_limit, 100))
)
update public.crm_workflow_queue q
set status = 'processing', claimed_at = now(), attempts = attempts + 1
from c
where q.id = c.id
returning q.*;
$$;
