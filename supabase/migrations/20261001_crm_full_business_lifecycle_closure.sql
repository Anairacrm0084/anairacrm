-- CRM full business-lifecycle closure
-- Applied to the connected production project during closure; retained here as source migration.

create table if not exists public.crm_workflow_jobs(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, workflow_id uuid, customer_id uuid,
 status text not null default 'queued', action_type text, payload jsonb not null default '{}', attempts integer not null default 0,
 max_attempts integer not null default 5, available_at timestamptz not null default now(), locked_at timestamptz,
 completed_at timestamptz, last_error text, created_at timestamptz not null default now()
);
create table if not exists public.crm_workflow_dlq(
 id uuid primary key default gen_random_uuid(), job_id uuid not null, tenant_id uuid not null, property_id uuid,
 reason text, payload jsonb not null default '{}', created_at timestamptz not null default now(), resolved_at timestamptz
);
create table if not exists public.crm_ai_action_runs(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, customer_id uuid, insight_id uuid,
 action_type text not null, status text not null default 'generated', model_name text, model_version text, prompt_version text,
 input_snapshot jsonb not null default '{}', output jsonb not null default '{}', confidence numeric, approved_by uuid,
 approved_at timestamptz, executed_at timestamptz, outcome jsonb, created_at timestamptz not null default now()
);
create table if not exists public.crm_commercial_offers(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, customer_id uuid, source_stay_id uuid,
 offer_type text not null, title text not null, price numeric not null default 0, currency text not null default 'INR', inventory_ref text,
 status text not null default 'draft', expires_at timestamptz, accepted_at timestamptz, paid_at timestamptz, fulfilled_at timestamptz,
 revenue numeric default 0, metadata jsonb not null default '{}', created_at timestamptz not null default now()
);
create table if not exists public.crm_event_pipeline(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, event_id uuid, stage text not null default 'lead',
 status text not null default 'open', proposal jsonb not null default '{}', contract jsonb not null default '{}', attendees jsonb not null default '[]',
 feedback jsonb not null default '{}', revenue numeric not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.crm_service_sla_events(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, ticket_id uuid, complaint_id uuid,
 event_type text not null, due_at timestamptz, actor_id uuid, payload jsonb not null default '{}', created_at timestamptz not null default now()
);
create table if not exists public.crm_privacy_requests(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, customer_id uuid not null,
 request_type text not null, status text not null default 'requested', verification_status text not null default 'pending',
 requested_at timestamptz not null default now(), completed_at timestamptz, output_ref text, metadata jsonb not null default '{}'
);
create table if not exists public.crm_revenue_publications(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, room_type_id uuid, rate_plan_id uuid, forecast_id uuid,
 old_rate numeric, recommended_rate numeric, published_rate numeric, status text not null default 'draft', authorized_by uuid,
 published_at timestamptz, booking_result_count integer default 0, revenue_result numeric default 0, performance jsonb not null default '{}', created_at timestamptz not null default now()
);
create table if not exists public.crm_forecast_accuracy(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, forecast_id uuid, forecast_date date,
 metric text not null, forecast_value numeric, actual_value numeric, error numeric, measured_at timestamptz not null default now()
);
create table if not exists public.crm_competitor_alerts(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid, competitor_name text, stay_date date, room_type_label text,
 our_rate numeric, competitor_rate numeric, variance numeric, status text not null default 'open', created_at timestamptz not null default now(), resolved_at timestamptz
);

do $$ declare t text; begin
 for t in select unnest(array['crm_workflow_jobs','crm_workflow_dlq','crm_ai_action_runs','crm_commercial_offers','crm_event_pipeline','crm_service_sla_events','crm_privacy_requests','crm_revenue_publications','crm_forecast_accuracy','crm_competitor_alerts']) loop
   execute format('alter table public.%I enable row level security',t);
   execute format('drop policy if exists crm_tenant_access on public.%I',t);
   execute format('create policy crm_tenant_access on public.%I for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id))',t);
 end loop;
end $$;

create index if not exists idx_crm_workflow_jobs_ready on public.crm_workflow_jobs(tenant_id,status,available_at);
create index if not exists idx_crm_commercial_offers_customer on public.crm_commercial_offers(tenant_id,property_id,customer_id,status);
create index if not exists idx_crm_event_pipeline_event on public.crm_event_pipeline(tenant_id,property_id,event_id);
create index if not exists idx_crm_privacy_customer on public.crm_privacy_requests(tenant_id,property_id,customer_id,status);

create or replace function public.anaira_crm_transition_workflow_job(p_job_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare j public.crm_workflow_jobs; v_id uuid;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 select * into j from public.crm_workflow_jobs where id=p_job_id for update;
 if j.id is null then raise exception 'JOB_NOT_FOUND'; end if;
 if not public.anaira_can_access_tenant(j.tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;
 if j.status not in ('queued','retry') then return jsonb_build_object('ok',false,'status',j.status); end if;
 update public.crm_workflow_jobs set status='processing',locked_at=now(),attempts=attempts+1 where id=p_job_id;
 begin
   if j.customer_id is not null then
     v_id:=public.anaira_record_crm_timeline(j.tenant_id,j.customer_id,'workflow_action','crm_workflow',j.id::text,coalesce(j.action_type,'workflow action'),'Workflow job executed',null,j.payload,now());
   end if;
   update public.crm_workflow_jobs set status='completed',completed_at=now(),locked_at=null where id=p_job_id;
   return jsonb_build_object('ok',true,'status','completed','timeline_id',v_id);
 exception when others then
   if j.attempts >= j.max_attempts then
     update public.crm_workflow_jobs set status='dead_letter',last_error=sqlerrm,locked_at=null where id=p_job_id;
     insert into public.crm_workflow_dlq(job_id,tenant_id,property_id,reason,payload) values(j.id,j.tenant_id,j.property_id,sqlerrm,j.payload);
   else
     update public.crm_workflow_jobs set status='retry',last_error=sqlerrm,available_at=now()+interval '5 minutes',locked_at=null where id=p_job_id;
   end if;
   raise;
 end;
end $$;
revoke all on function public.anaira_crm_transition_workflow_job(uuid) from public,anon;
grant execute on function public.anaira_crm_transition_workflow_job(uuid) to authenticated;
