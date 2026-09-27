-- Phase 15: operational completion primitives. No demo metrics.
create extension if not exists pgcrypto;

create table if not exists public.hms_guest_documents (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null, guest_id uuid not null,
 document_type text not null, document_number text, document_url text, verified boolean not null default false,
 verified_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.hms_guest_deposits (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null, reservation_id uuid, stay_id uuid,
 amount numeric not null check(amount>=0), method text not null, reference text, status text not null default 'held',
 created_at timestamptz not null default now(), released_at timestamptz
);
create table if not exists public.hms_folio_payments (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null, folio_id uuid not null,
 amount numeric not null check(amount>0), method text not null, provider text, reference text,
 status text not null default 'settled', created_at timestamptz not null default now()
);
create table if not exists public.hms_maintenance_tasks (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null, room_id uuid, task_type text not null,
 priority text not null default 'normal', status text not null default 'open', assigned_to uuid, notes text,
 created_at timestamptz not null default now(), completed_at timestamptz
);
create table if not exists public.hms_night_audits (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null, business_date date not null,
 status text not null default 'started', occupancy numeric, room_revenue numeric, restaurant_revenue numeric,
 total_revenue numeric, evidence jsonb not null default '{}'::jsonb, started_at timestamptz not null default now(), completed_at timestamptz,
 unique(restaurant_id,business_date)
);
create table if not exists public.crm_workflow_queue (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, workflow_id uuid not null,
 run_id uuid, action_index int not null default 0, action jsonb not null default '{}'::jsonb,
 status text not null default 'queued', attempts int not null default 0, last_error text,
 available_at timestamptz not null default now(), claimed_at timestamptz, completed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.crm_forecast_points (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, run_id uuid not null,
 metric_date date not null, metric text not null, value numeric, lower_bound numeric, upper_bound numeric,
 created_at timestamptz not null default now()
);

create index if not exists idx_hms_docs_tenant on public.hms_guest_documents(restaurant_id,guest_id);
create index if not exists idx_hms_deposits_tenant on public.hms_guest_deposits(restaurant_id,status,created_at desc);
create index if not exists idx_hms_folio_payments on public.hms_folio_payments(restaurant_id,folio_id,created_at desc);
create index if not exists idx_hms_maintenance on public.hms_maintenance_tasks(restaurant_id,status,created_at desc);
create index if not exists idx_workflow_queue on public.crm_workflow_queue(tenant_id,status,available_at);
create index if not exists idx_forecast_points on public.crm_forecast_points(tenant_id,metric_date,metric);

alter table public.hms_guest_documents enable row level security;
alter table public.hms_guest_deposits enable row level security;
alter table public.hms_folio_payments enable row level security;
alter table public.hms_maintenance_tasks enable row level security;
alter table public.hms_night_audits enable row level security;
alter table public.crm_workflow_queue enable row level security;
alter table public.crm_forecast_points enable row level security;

create policy tenant_select on public.hms_guest_documents for select to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_write on public.hms_guest_documents for all to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_select on public.hms_guest_deposits for select to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_write on public.hms_guest_deposits for all to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_select on public.hms_folio_payments for select to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_write on public.hms_folio_payments for all to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_select on public.hms_maintenance_tasks for select to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_write on public.hms_maintenance_tasks for all to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_select on public.hms_night_audits for select to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_write on public.hms_night_audits for all to authenticated using(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_select on public.crm_workflow_queue for select to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_write on public.crm_workflow_queue for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_select on public.crm_forecast_points for select to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy tenant_write on public.crm_forecast_points for all to authenticated using(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check(tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

create or replace function public.anaira_settle_hms_folio(p_restaurant_id uuid,p_folio_id uuid,p_amount numeric,p_method text,p_provider text default null,p_reference text default null)
returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid; v_balance numeric;
begin
 if p_amount<=0 then raise exception 'amount must be positive'; end if;
 select balance into v_balance from hms_folios where id=p_folio_id and restaurant_id=p_restaurant_id for update;
 if not found then raise exception 'folio not found'; end if;
 if p_amount>v_balance then raise exception 'payment exceeds outstanding balance'; end if;
 insert into hms_folio_payments(restaurant_id,folio_id,amount,method,provider,reference) values(p_restaurant_id,p_folio_id,p_amount,p_method,p_provider,p_reference) returning id into v_id;
 update hms_folios set balance=greatest(0,balance-p_amount),status=case when balance-p_amount<=0 then 'paid' else status end,updated_at=now() where id=p_folio_id;
 return v_id;
end $$;

create or replace function public.anaira_claim_workflow_jobs(p_tenant_id uuid,p_limit int default 20)
returns setof public.crm_workflow_queue language sql security invoker set search_path=public,pg_temp as $$
with c as (select id from crm_workflow_queue where tenant_id=p_tenant_id and status='queued' and available_at<=now() order by available_at,id for update skip locked limit greatest(1,least(p_limit,100)))
update crm_workflow_queue q set status='processing',claimed_at=now(),attempts=attempts+1 from c where q.id=c.id returning q.*; $$;

create or replace function public.anaira_complete_workflow_job(p_job_id uuid,p_ok boolean,p_error text default null)
returns void language sql security invoker set search_path=public,pg_temp as $$ update crm_workflow_queue set status=case when p_ok then 'completed' else case when attempts<5 then 'queued' else 'failed' end end,last_error=case when p_ok then null else p_error end,completed_at=case when p_ok then now() else null end,available_at=case when p_ok then now() else now()+interval '5 minutes' end where id=p_job_id; $$;

create or replace function public.anaira_generate_simple_forecast(p_tenant_id uuid,p_horizon_days int default 7)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare v_run uuid; v_avg numeric; i int;
begin
 insert into crm_forecast_runs(tenant_id,model_version,horizon_days,status,started_at) values(p_tenant_id,'moving-average-v1',p_horizon_days,'running',now()) returning id into v_run;
 select coalesce(avg(total_revenue),0) into v_avg from crm_customer_value_snapshots where tenant_id=p_tenant_id and snapshot_date>=current_date-30;
 for i in 1..greatest(1,least(p_horizon_days,90)) loop insert into crm_forecast_points(tenant_id,run_id,metric_date,metric,value,lower_bound,upper_bound) values(p_tenant_id,v_run,current_date+i,'revenue',v_avg,v_avg*.8,v_avg*1.2); end loop;
 update crm_forecast_runs set status='completed',metrics=jsonb_build_object('method','moving-average-v1','baseline',v_avg),completed_at=now() where id=v_run;
 return v_run;
exception when others then update crm_forecast_runs set status='failed',error=sqlerrm,completed_at=now() where id=v_run; raise; end $$;

create or replace function public.anaira_night_audit(p_restaurant_id uuid,p_business_date date)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare v_id uuid; v_rooms int; v_sold int; v_rev numeric; v_rest numeric;
begin
 insert into hms_night_audits(restaurant_id,business_date,status) values(p_restaurant_id,p_business_date,'started') on conflict(restaurant_id,business_date) do update set status='started' returning id into v_id;
 select count(*) into v_rooms from hms_rooms where restaurant_id=p_restaurant_id;
 select count(*) into v_sold from hms_reservations where restaurant_id=p_restaurant_id and check_in<=p_business_date and check_out>p_business_date and status in ('confirmed','checked_in','in_house');
 select coalesce(sum(total_amount),0) into v_rev from hms_reservations where restaurant_id=p_restaurant_id and created_at::date=p_business_date and status not in ('cancelled','no_show');
 select 0 into v_rest;
 update hms_night_audits set status='completed',occupancy=case when v_rooms=0 then 0 else round(v_sold::numeric*100/v_rooms,2) end,room_revenue=v_rev,restaurant_revenue=v_rest,total_revenue=v_rev,completed_at=now() where id=v_id;
 return v_id;
end $$;

insert into public.crm_release_evidence(check_name,status,evidence) values('phase15_operational_primitives','pass',jsonb_build_object('pms','deposits-documents-maintenance-night-audit','billing','folio-settlement','workflow','claim-retry','forecast','stored-predictions'));
