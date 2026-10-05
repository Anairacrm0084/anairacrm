-- Anaira Corporate CRM production runtime closure
-- Reproducible schema/RPC/worker layer for corporate accounts.
create table if not exists public.crm_corporate_bookings(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
 reservation_id uuid references public.hms_reservations(id) on delete set null,
 booking_reference text, room_allocation jsonb not null default '{}'::jsonb,
 amount numeric not null default 0, status text not null default 'draft',
 invoice_status text not null default 'unbilled', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists crm_corporate_bookings_scope_idx on public.crm_corporate_bookings(tenant_id,property_id,corporate_account_id,created_at desc);
alter table public.crm_corporate_bookings enable row level security;
drop policy if exists crm_corporate_bookings_scope on public.crm_corporate_bookings;
create policy crm_corporate_bookings_scope on public.crm_corporate_bookings for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_corporate_invoices(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
 booking_id uuid references public.crm_corporate_bookings(id) on delete set null,
 invoice_number text not null, issue_date date not null default current_date, due_date date,
 subtotal numeric not null default 0, tax numeric not null default 0, total numeric not null default 0,
 paid_amount numeric not null default 0, status text not null default 'open', created_at timestamptz not null default now()
);
create unique index if not exists crm_corporate_invoices_number_uq on public.crm_corporate_invoices(tenant_id,invoice_number);
create index if not exists crm_corporate_invoices_scope_idx on public.crm_corporate_invoices(tenant_id,property_id,corporate_account_id,issue_date desc);
alter table public.crm_corporate_invoices enable row level security;
drop policy if exists crm_corporate_invoices_scope on public.crm_corporate_invoices;
create policy crm_corporate_invoices_scope on public.crm_corporate_invoices for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_corporate_rate_agreements(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
 contract_id uuid references public.crm_corporate_contracts(id) on delete set null,
 room_type_id uuid, rate_plan_id uuid, rate numeric not null default 0, currency text not null default 'INR',
 meal_plan text, valid_from date not null default current_date, valid_to date,
 terms jsonb not null default '{}'::jsonb, active boolean not null default true, created_at timestamptz not null default now()
);
create index if not exists crm_corporate_rates_scope_idx on public.crm_corporate_rate_agreements(tenant_id,property_id,corporate_account_id,valid_from,valid_to);
alter table public.crm_corporate_rate_agreements enable row level security;
drop policy if exists crm_corporate_rates_scope on public.crm_corporate_rate_agreements;
create policy crm_corporate_rates_scope on public.crm_corporate_rate_agreements for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_corporate_renewal_jobs(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
 contract_id uuid references public.crm_corporate_contracts(id) on delete cascade,
 run_at timestamptz not null, status text not null default 'queued', attempts integer not null default 0,
 max_attempts integer not null default 5, last_error text, created_at timestamptz not null default now(), unique(contract_id,run_at)
);
alter table public.crm_corporate_renewal_jobs enable row level security;
drop policy if exists crm_corporate_renewal_jobs_scope on public.crm_corporate_renewal_jobs;
create policy crm_corporate_renewal_jobs_scope on public.crm_corporate_renewal_jobs for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_corporate_contract_action(p_account_id uuid,p_action text,p_end_date date default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.crm_corporate_accounts%rowtype; c public.crm_corporate_contracts%rowtype; cid uuid;
begin
 select * into a from public.crm_corporate_accounts where id=p_account_id for update;
 if not found then raise exception 'Corporate account not found'; end if;
 if not public.anaira_can_access_tenant(a.tenant_id) then raise exception 'Unauthorized'; end if;
 if p_action='create_contract' then
  insert into public.crm_corporate_contracts(corporate_account_id,tenant_id,property_id,contract_number,start_date,end_date,negotiated_terms,status)
  values(a.id,a.tenant_id,a.property_id,'CORP-'||to_char(clock_timestamp(),'YYYYMMDDHH24MISSMS'),current_date,coalesce(p_end_date,current_date+365),jsonb_build_object('payment_terms',a.payment_terms,'credit_limit',a.credit_limit,'negotiated_rates',a.negotiated_rates),'draft') returning * into c;
 elsif p_action='approve_contract' then
  select id into cid from public.crm_corporate_contracts where corporate_account_id=a.id and status in ('draft','pending') and tenant_id=a.tenant_id order by end_date desc limit 1;
  if cid is null then raise exception 'No draft contract found'; end if;
  update public.crm_corporate_contracts set status='active',approved_by=auth.uid(),approved_at=now() where id=cid returning * into c;
 elsif p_action='renew_contract' then
  select id into cid from public.crm_corporate_contracts where corporate_account_id=a.id and tenant_id=a.tenant_id order by end_date desc limit 1;
  if cid is null then raise exception 'No contract found'; end if;
  update public.crm_corporate_contracts set end_date=coalesce(p_end_date,current_date+365),renewal_status='renewed',status='active' where id=cid returning * into c;
 else raise exception 'Unsupported corporate contract action'; end if;
 update public.crm_corporate_accounts set contract_expiry=c.end_date where id=a.id;
 insert into public.crm_audit_logs(tenant_id,property_id,action,entity_type,entity_id,after_data) values(a.tenant_id,a.property_id,p_action,'crm_corporate_contracts',c.id,to_jsonb(c));
 return jsonb_build_object('ok',true,'account_id',a.id,'contract_id',c.id,'status',c.status,'end_date',c.end_date);
end $$;
revoke all on function public.anaira_corporate_contract_action(uuid,text,date) from public;
grant execute on function public.anaira_corporate_contract_action(uuid,text,date) to authenticated;

create or replace function public.anaira_corporate_record_ledger(p_account_id uuid,p_entry_type text,p_amount numeric,p_reference_number text default null,p_description text default null,p_due_date date default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.crm_corporate_accounts%rowtype; bal numeric; e public.crm_corporate_ledger%rowtype;
begin
 select * into a from public.crm_corporate_accounts where id=p_account_id for update;
 if not found then raise exception 'Corporate account not found'; end if;
 if not public.anaira_can_access_tenant(a.tenant_id) then raise exception 'Unauthorized'; end if;
 bal:=greatest(0,coalesce(a.credit_used,0)+coalesce(p_amount,0));
 insert into public.crm_corporate_ledger(tenant_id,property_id,corporate_account_id,entry_type,reference_number,description,amount,balance_after,due_date)
 values(a.tenant_id,a.property_id,a.id,p_entry_type,p_reference_number,p_description,coalesce(p_amount,0),bal,p_due_date) returning * into e;
 update public.crm_corporate_accounts set credit_used=bal where id=a.id;
 insert into public.crm_audit_logs(tenant_id,property_id,action,entity_type,entity_id,after_data) values(a.tenant_id,a.property_id,'ledger_entry','crm_corporate_accounts',a.id,jsonb_build_object('entry_id',e.id,'amount',p_amount,'balance',bal));
 return jsonb_build_object('ok',true,'entry_id',e.id,'balance',bal,'credit_limit',a.credit_limit);
end $$;
revoke all on function public.anaira_corporate_record_ledger(uuid,text,numeric,text,text,date) from public;
grant execute on function public.anaira_corporate_record_ledger(uuid,text,numeric,text,text,date) to authenticated;

create or replace function public.anaira_corporate_queue_expiry_jobs() returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare n integer;
begin
 insert into public.crm_corporate_renewal_jobs(tenant_id,property_id,corporate_account_id,contract_id,run_at)
 select c.tenant_id,c.property_id,c.corporate_account_id,c.id,now() from public.crm_corporate_contracts c
 where c.end_date between current_date and current_date+90 and c.status='active' on conflict do nothing;
 get diagnostics n=row_count; return n;
end $$;
revoke all on function public.anaira_corporate_queue_expiry_jobs() from public;
grant execute on function public.anaira_corporate_queue_expiry_jobs() to service_role;

create table if not exists public.crm_corporate_statements(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
 statement_number text not null, period_from date not null, period_to date not null,
 opening_balance numeric not null default 0, charges numeric not null default 0, payments numeric not null default 0,
 closing_balance numeric not null default 0, generated_at timestamptz not null default now()
);
create unique index if not exists crm_corporate_statements_number_uq on public.crm_corporate_statements(tenant_id,statement_number);
alter table public.crm_corporate_statements enable row level security;
drop policy if exists crm_corporate_statements_scope on public.crm_corporate_statements;
create policy crm_corporate_statements_scope on public.crm_corporate_statements for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create table if not exists public.crm_corporate_revenue_attribution(
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, property_id uuid,
 corporate_account_id uuid not null references public.crm_corporate_accounts(id) on delete cascade,
 booking_id uuid references public.crm_corporate_bookings(id) on delete set null,
 invoice_id uuid references public.crm_corporate_invoices(id) on delete set null,
 revenue_date date not null default current_date, gross_amount numeric not null default 0, net_amount numeric not null default 0,
 source text not null default 'corporate-crm', created_at timestamptz not null default now()
);
create index if not exists crm_corporate_revenue_scope_idx on public.crm_corporate_revenue_attribution(tenant_id,property_id,corporate_account_id,revenue_date desc);
alter table public.crm_corporate_revenue_attribution enable row level security;
drop policy if exists crm_corporate_revenue_scope on public.crm_corporate_revenue_attribution;
create policy crm_corporate_revenue_scope on public.crm_corporate_revenue_attribution for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_corporate_generate_statement(p_account_id uuid,p_from date,p_to date) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.crm_corporate_accounts%rowtype; op numeric; ch numeric; pay numeric; cl numeric; s public.crm_corporate_statements%rowtype;
begin
 select * into a from public.crm_corporate_accounts where id=p_account_id for update;
 if not found or not public.anaira_can_access_tenant(a.tenant_id) then raise exception 'Unauthorized or account not found'; end if;
 select coalesce(sum(case when amount>0 then amount else 0 end),0),coalesce(sum(case when amount<0 then -amount else 0 end),0) into ch,pay from public.crm_corporate_ledger where corporate_account_id=a.id and tenant_id=a.tenant_id and created_at::date between p_from and p_to;
 select coalesce(sum(amount),0) into op from public.crm_corporate_ledger where corporate_account_id=a.id and tenant_id=a.tenant_id and created_at::date < p_from;
 cl:=greatest(0,op+ch-pay);
 insert into public.crm_corporate_statements(tenant_id,property_id,corporate_account_id,statement_number,period_from,period_to,opening_balance,charges,payments,closing_balance) values(a.tenant_id,a.property_id,a.id,'STMT-'||to_char(clock_timestamp(),'YYYYMMDDHH24MISSMS'),p_from,p_to,greatest(0,op),ch,pay,cl) returning * into s;
 insert into public.crm_audit_logs(tenant_id,property_id,action,entity_type,entity_id,after_data) values(a.tenant_id,a.property_id,'statement_generated','crm_corporate_statements',s.id,to_jsonb(s));
 return to_jsonb(s);
end $$;
revoke all on function public.anaira_corporate_generate_statement(uuid,date,date) from public;
grant execute on function public.anaira_corporate_generate_statement(uuid,date,date) to authenticated;

create or replace function public.anaira_corporate_record_revenue(p_account_id uuid,p_booking_id uuid default null,p_invoice_id uuid default null,p_gross numeric default 0,p_net numeric default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.crm_corporate_accounts%rowtype; r public.crm_corporate_revenue_attribution%rowtype; n numeric;
begin
 select * into a from public.crm_corporate_accounts where id=p_account_id;
 if not found or not public.anaira_can_access_tenant(a.tenant_id) then raise exception 'Unauthorized or account not found'; end if;
 n:=coalesce(p_net,p_gross);
 insert into public.crm_corporate_revenue_attribution(tenant_id,property_id,corporate_account_id,booking_id,invoice_id,gross_amount,net_amount) values(a.tenant_id,a.property_id,a.id,p_booking_id,p_invoice_id,coalesce(p_gross,0),n) returning * into r;
 insert into public.crm_audit_logs(tenant_id,property_id,action,entity_type,entity_id,after_data) values(a.tenant_id,a.property_id,'revenue_attributed','crm_corporate_revenue_attribution',r.id,to_jsonb(r));
 return to_jsonb(r);
end $$;
revoke all on function public.anaira_corporate_record_revenue(uuid,uuid,uuid,numeric,numeric) from public;
grant execute on function public.anaira_corporate_record_revenue(uuid,uuid,uuid,numeric,numeric) to authenticated;

create or replace function public.anaira_process_corporate_renewal_jobs(p_limit integer default 50) returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare j record; n integer:=0;
begin
 for j in select * from public.crm_corporate_renewal_jobs where status='queued' and run_at<=now() order by run_at limit greatest(1,p_limit) for update skip locked loop
  begin
   update public.crm_corporate_renewal_jobs set status='processing',attempts=attempts+1 where id=j.id;
   update public.crm_corporate_contracts set renewal_status=case when end_date<current_date then 'expired' else 'renewal_due' end where id=j.contract_id;
   insert into public.crm_notifications(tenant_id,property_id,notification_type,title,body,severity,action_url) values(j.tenant_id,j.property_id,'corporate_renewal','Corporate contract renewal due','Corporate account renewal requires review.','warning','/corporate-crm');
   insert into public.crm_audit_logs(tenant_id,property_id,action,entity_type,entity_id,after_data) values(j.tenant_id,j.property_id,'renewal_job_processed','crm_corporate_contracts',j.contract_id,jsonb_build_object('job_id',j.id,'attempts',j.attempts+1));
   update public.crm_corporate_renewal_jobs set status='completed' where id=j.id; n:=n+1;
  exception when others then
   update public.crm_corporate_renewal_jobs set status=case when attempts>=max_attempts then 'dead_letter' else 'queued' end,last_error=sqlerrm,run_at=now()+make_interval(mins=>least(60,2^attempts)) where id=j.id;
  end;
 end loop;
 return n;
end $$;
revoke all on function public.anaira_process_corporate_renewal_jobs(integer) from public;
grant execute on function public.anaira_process_corporate_renewal_jobs(integer) to service_role;
select cron.unschedule('anaira_corporate_renewal_worker') where exists(select 1 from cron.job where jobname='anaira_corporate_renewal_worker');
select cron.schedule('anaira_corporate_renewal_worker','*/5 * * * *',$$select public.anaira_corporate_queue_expiry_jobs(); select public.anaira_process_corporate_renewal_jobs(50);$$);

alter table public.crm_corporate_contacts add column if not exists contact_name text;
alter table public.crm_corporate_contacts add column if not exists email text;
alter table public.crm_corporate_contacts add column if not exists phone text;
create index if not exists crm_corporate_contacts_scope_idx on public.crm_corporate_contacts(tenant_id,property_id,corporate_account_id);
alter table public.crm_corporate_bookings add column if not exists room_type_id uuid;
alter table public.crm_corporate_bookings add column if not exists room_id uuid;
alter table public.crm_corporate_bookings add column if not exists check_in date;
alter table public.crm_corporate_bookings add column if not exists check_out date;
create index if not exists crm_corporate_bookings_room_idx on public.crm_corporate_bookings(property_id,room_type_id,room_id,check_in,check_out);
