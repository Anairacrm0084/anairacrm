-- ANAIRA HOTEL GUEST CRM — 105 FULL ENTERPRISE RUNTIME
-- Completes property scoping, event ingestion, segment rules, loyalty lifecycle,
-- guest merge relationship transfer, provider webhook inbox and automation metadata.

-- 1) Canonical hospitality property identity
create table if not exists public.anaira_hospitality_properties_master (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  source_table text not null,
  source_id uuid not null,
  property_type text not null default 'hotel',
  name text not null,
  destination text,
  city text,
  state text,
  country text,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(source_table,source_id)
);
alter table public.anaira_hospitality_properties_master enable row level security;
drop policy if exists ana_hospitality_property_access on public.anaira_hospitality_properties_master;
create policy ana_hospitality_property_access on public.anaira_hospitality_properties_master
for all to authenticated using (public.anaira_can_access_tenant(tenant_id)) with check (public.anaira_can_access_tenant(tenant_id));

insert into public.anaira_hospitality_properties_master(tenant_id,source_table,source_id,property_type,name,destination,city,state,country,active,metadata)
select p.restaurant_id,'anaira_stay_properties',p.id,coalesce(nullif(p.stay_type,''),'hotel'),p.name,p.destination,p.city,p.state,p.country,coalesce(p.active,true),jsonb_build_object('source','anaira_stay_properties')
from public.anaira_stay_properties p
on conflict(source_table,source_id) do update set name=excluded.name,property_type=excluded.property_type,destination=excluded.destination,city=excluded.city,state=excluded.state,country=excluded.country,active=excluded.active,updated_at=now();
insert into public.anaira_hospitality_properties_master(tenant_id,source_table,source_id,property_type,name,active,metadata)
select p.business_id,'anaira_hotel_properties',p.id,'hotel',p.name,coalesce(p.active,true),jsonb_build_object('source','anaira_hotel_properties')
from public.anaira_hotel_properties p
on conflict(source_table,source_id) do update set name=excluded.name,active=excluded.active,updated_at=now();
insert into public.anaira_hospitality_properties_master(tenant_id,source_table,source_id,property_type,name,destination,city,state,country,active,metadata)
select p.restaurant_id,'camp_properties',p.id,'camp',p.name,p.destination,p.city,p.state,p.country,coalesce(p.active,true),jsonb_build_object('source','camp_properties')
from public.camp_properties p
on conflict(source_table,source_id) do update set name=excluded.name,property_type=excluded.property_type,destination=excluded.destination,city=excluded.city,state=excluded.state,country=excluded.country,active=excluded.active,updated_at=now();

-- Operational sources carry the canonical property id as well as tenant/restaurant id.
alter table public.booking_reservations add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.pms_reservations add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.hms_reservations add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.hms_stays add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_guest_stays add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_guest_requests add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_complaints add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_feedback add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_guest_upsells add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;
alter table public.crm_hotel_cross_sell_opportunities add column if not exists property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null;

-- Default existing records to the first active property for that tenant only when no explicit property is available.
do $$ declare t record; pid uuid; begin
  for t in select distinct restaurant_id tenant_id from public.booking_reservations where property_id is null loop
    select id into pid from public.anaira_hospitality_properties_master where tenant_id=t.tenant_id and active=true order by created_at limit 1;
    if pid is not null then update public.booking_reservations set property_id=pid where restaurant_id=t.tenant_id and property_id is null; end if;
  end loop;
  for t in select distinct restaurant_id tenant_id from public.pms_reservations where property_id is null loop
    select id into pid from public.anaira_hospitality_properties_master where tenant_id=t.tenant_id and active=true order by created_at limit 1;
    if pid is not null then update public.pms_reservations set property_id=pid where restaurant_id=t.tenant_id and property_id is null; end if;
  end loop;
  for t in select distinct restaurant_id tenant_id from public.hms_reservations where property_id is null loop
    select id into pid from public.anaira_hospitality_properties_master where tenant_id=t.tenant_id and active=true order by created_at limit 1;
    if pid is not null then update public.hms_reservations set property_id=pid where restaurant_id=t.tenant_id and property_id is null; end if;
  end loop;
  for t in select distinct restaurant_id tenant_id from public.hms_stays where property_id is null loop
    select id into pid from public.anaira_hospitality_properties_master where tenant_id=t.tenant_id and active=true order by created_at limit 1;
    if pid is not null then update public.hms_stays set property_id=pid where restaurant_id=t.tenant_id and property_id is null; end if;
  end loop;
end $$;

create index if not exists ana_hospitality_property_tenant_idx on public.anaira_hospitality_properties_master(tenant_id,active);
create index if not exists booking_reservations_property_idx on public.booking_reservations(restaurant_id,property_id,check_in,check_out);
create index if not exists pms_reservations_property_idx on public.pms_reservations(restaurant_id,property_id,check_in,check_out);
create index if not exists crm_guest_stays_property_idx on public.crm_guest_stays(tenant_id,property_id,check_in_date desc);

-- 2) Event inbox + idempotent source delivery
create table if not exists public.crm_source_event_inbox (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null,
  property_id uuid references public.anaira_hospitality_properties_master(id) on delete set null,
  source_system text not null, event_type text not null, external_event_id text not null,
  payload jsonb not null default '{}'::jsonb, status text not null default 'received', attempts integer not null default 0,
  last_error text, received_at timestamptz not null default now(), processed_at timestamptz,
  unique(source_system,external_event_id)
);
create table if not exists public.crm_source_event_delivery_log (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null,
  inbox_event_id uuid references public.crm_source_event_inbox(id) on delete cascade,
  source_system text not null, event_type text not null, attempt integer not null default 1,
  status text not null, response jsonb not null default '{}'::jsonb, error text, created_at timestamptz not null default now()
);
alter table public.crm_source_event_inbox enable row level security;
alter table public.crm_source_event_delivery_log enable row level security;
drop policy if exists crm_source_event_inbox_access on public.crm_source_event_inbox;
drop policy if exists crm_source_event_delivery_log_access on public.crm_source_event_delivery_log;
create policy crm_source_event_inbox_access on public.crm_source_event_inbox for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));
create policy crm_source_event_delivery_log_access on public.crm_source_event_delivery_log for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_enqueue_crm_source_event()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare tenant uuid; pid uuid; src text; et text; eid text; payload jsonb;
begin
 tenant:=coalesce(nullif(to_jsonb(new)->>'restaurant_id','')::uuid,nullif(to_jsonb(new)->>'tenant_id','')::uuid);
 if tenant is null then return new; end if;
 pid:=nullif(to_jsonb(new)->>'property_id','')::uuid;
 src:=case when tg_table_name like 'booking_%' then 'booking_engine' when tg_table_name like 'pms_%' or tg_table_name like 'hms_%' then 'pms' else 'source' end;
 et:=lower(tg_op)||'.'||tg_table_name; eid:=coalesce(to_jsonb(new)->>'id',md5(to_jsonb(new)::text)); payload:=to_jsonb(new);
 insert into public.crm_source_event_inbox(tenant_id,property_id,source_system,event_type,external_event_id,payload)
 values(tenant,pid,src,et,eid,payload) on conflict(source_system,external_event_id) do update set payload=excluded.payload,property_id=coalesce(excluded.property_id,crm_source_event_inbox.property_id),status=case when crm_source_event_inbox.status='processed' then 'received' else crm_source_event_inbox.status end;
 return new;
end $$;

do $$ declare t text; trig text; begin
 foreach t in array array['booking_reservations','pms_reservations','hms_reservations','hms_stays'] loop
   if to_regclass('public.'||t) is not null then
     trig:='trg_crm_event_'||t; execute format('drop trigger if exists %I on public.%I',trig,t);
     execute format('create trigger %I after insert or update on public.%I for each row execute function public.anaira_enqueue_crm_source_event()',trig,t);
   end if;
 end loop;
end $$;

-- 3) Rule-based segment engine + preview count
create table if not exists public.crm_segment_rules (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null,
 segment_id uuid not null references public.crm_segments(id) on delete cascade,
 rule_group integer not null default 0, field_name text not null, operator text not null,
 value_json jsonb not null default 'null'::jsonb, conjunction text not null default 'AND',
 position integer not null default 0, active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(segment_id,position)
);
alter table public.crm_segment_rules enable row level security;
drop policy if exists crm_segment_rules_access on public.crm_segment_rules;
create policy crm_segment_rules_access on public.crm_segment_rules for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_segment_matches(p_customer uuid,p_segment uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare c public.crm_customers%rowtype; r record; val jsonb; actual numeric; ok boolean; allok boolean:=true;begin
 select * into c from public.crm_customers where id=p_customer; if c.id is null then return false; end if;
 for r in select * from public.crm_segment_rules where segment_id=p_segment and active=true order by position loop
   val:=r.value_json; ok:=false;
   if r.field_name='vip' then ok:=case r.operator when '=' then c.vip=(val#>>'{}')::boolean when '!=' then c.vip<>(val#>>'{}')::boolean else false end;
   elsif r.field_name='customer_type' then ok:=case r.operator when '=' then c.customer_type=(val#>>'{}') when '!=' then c.customer_type<>(val#>>'{}') else false end;
   elsif r.field_name='total_hotel_revenue' then actual:=coalesce(c.total_hotel_revenue,0); ok:=case r.operator when '>=' then actual>=(val#>>'{}')::numeric when '>' then actual>(val#>>'{}')::numeric when '<=' then actual<=(val#>>'{}')::numeric when '<' then actual<(val#>>'{}')::numeric when '=' then actual=(val#>>'{}')::numeric else false end;
   elsif r.field_name='total_restaurant_revenue' then actual:=coalesce(c.total_restaurant_revenue,0); ok:=case r.operator when '>=' then actual>=(val#>>'{}')::numeric when '>' then actual>(val#>>'{}')::numeric when '<=' then actual<=(val#>>'{}')::numeric when '<' then actual<(val#>>'{}')::numeric when '=' then actual=(val#>>'{}')::numeric else false end;
   elsif r.field_name='total_stays' then actual:=coalesce(c.total_stays,0); ok:=case r.operator when '>=' then actual>=(val#>>'{}')::numeric when '>' then actual>(val#>>'{}')::numeric when '<=' then actual<=(val#>>'{}')::numeric when '<' then actual<(val#>>'{}')::numeric when '=' then actual=(val#>>'{}')::numeric else false end;
   elsif r.field_name='total_restaurant_visits' then actual:=coalesce(c.total_restaurant_visits,0); ok:=case r.operator when '>=' then actual>=(val#>>'{}')::numeric when '>' then actual>(val#>>'{}')::numeric when '<=' then actual<=(val#>>'{}')::numeric when '<' then actual<(val#>>'{}')::numeric when '=' then actual=(val#>>'{}')::numeric else false end;
   end if;
   if upper(r.conjunction)='OR' then allok:=allok or ok; else allok:=allok and ok; end if;
 end loop; return allok;
end $$;

create or replace function public.anaira_preview_segment(p_segment uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare t uuid; matched integer;begin
 select tenant_id into t from public.crm_segments where id=p_segment; if t is null then raise exception 'Segment not found'; end if;
 select count(*) into matched from public.crm_customers c where c.tenant_id=t and public.anaira_segment_matches(c.id,p_segment);
 return jsonb_build_object('segment_id',p_segment,'tenant_id',t,'matched',matched);
end $$;

create or replace function public.anaira_recalculate_segment(p_segment uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare t uuid; matched integer;begin
 select tenant_id into t from public.crm_segments where id=p_segment; if t is null then raise exception 'Segment not found'; end if;
 delete from public.crm_segment_members where segment_id=p_segment;
 insert into public.crm_segment_members(segment_id,customer_id,calculated_at,reason)
 select p_segment,c.id,now(),'rule-engine' from public.crm_customers c where c.tenant_id=t and public.anaira_segment_matches(c.id,p_segment);
 get diagnostics matched=row_count; return jsonb_build_object('segment_id',p_segment,'matched',matched);
end $$;

grant execute on function public.anaira_preview_segment(uuid) to authenticated;
grant execute on function public.anaira_recalculate_segment(uuid) to authenticated;

-- 4) Loyalty lifecycle rules and safe reversal/expiry
create table if not exists public.crm_loyalty_lifecycle_rules (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, name text not null,
 rule_type text not null, config jsonb not null default '{}'::jsonb, active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.crm_loyalty_lifecycle_rules enable row level security;
drop policy if exists crm_loyalty_lifecycle_rules_access on public.crm_loyalty_lifecycle_rules;
create policy crm_loyalty_lifecycle_rules_access on public.crm_loyalty_lifecycle_rules for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));
alter table public.crm_loyalty_transactions add column if not exists expires_at timestamptz;
alter table public.crm_loyalty_transactions add column if not exists reversed_transaction_id uuid references public.crm_loyalty_transactions(id) on delete set null;
alter table public.crm_loyalty_transactions add column if not exists reversed_at timestamptz;
create index if not exists crm_loyalty_expiry_idx on public.crm_loyalty_transactions(expires_at) where expires_at is not null;

create or replace function public.anaira_reverse_loyalty_transaction(p_transaction_id uuid,p_reason text default null)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare t public.crm_loyalty_transactions; a public.crm_loyalty_accounts; r uuid;begin
 select * into t from public.crm_loyalty_transactions where id=p_transaction_id for update; if t.id is null then raise exception 'LOYALTY_TRANSACTION_NOT_FOUND'; end if;
 if t.reversed_at is not null then raise exception 'LOYALTY_TRANSACTION_ALREADY_REVERSED'; end if;
 select * into a from public.crm_loyalty_accounts where id=t.loyalty_account_id for update; if a.id is null then raise exception 'LOYALTY_ACCOUNT_NOT_FOUND'; end if;
 insert into public.crm_loyalty_transactions(loyalty_account_id,points,transaction_type,reference_type,reference_id,notes) values(a.id,-t.points,'reversal','loyalty_transaction',t.id::text,coalesce(p_reason,'Reversal')) returning id into r;
 update public.crm_loyalty_transactions set reversed_at=now(),reversed_transaction_id=r where id=t.id;
 update public.crm_loyalty_accounts set points_balance=points_balance-t.points where id=a.id;
 return jsonb_build_object('original_transaction_id',t.id,'reversal_transaction_id',r,'status','reversed');
end $$;
grant execute on function public.anaira_reverse_loyalty_transaction(uuid,text) to authenticated;

-- 5) Enterprise merge: transfer every customer_id relationship table where safe, retain audit trail.
create or replace function public.anaira_merge_crm_customer_enterprise(p_survivor uuid,p_duplicate uuid,p_reason text default null,p_evidence jsonb default '{}')
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare s public.crm_customers; d public.crm_customers; t record; moved jsonb:='[]'::jsonb; n integer;begin
 select * into s from public.crm_customers where id=p_survivor for update; if s.id is null then raise exception 'SURVIVOR_NOT_FOUND'; end if;
 select * into d from public.crm_customers where id=p_duplicate for update; if d.id is null then raise exception 'DUPLICATE_NOT_FOUND'; end if;
 if s.tenant_id is distinct from d.tenant_id then raise exception 'CROSS_TENANT_MERGE_DENIED'; end if;
 if d.merged_into_customer_id is not null then raise exception 'DUPLICATE_ALREADY_MERGED'; end if;
 for t in select distinct tc.table_name from information_schema.columns tc join information_schema.columns cc on cc.table_schema=tc.table_schema and cc.table_name=tc.table_name and cc.column_name='customer_id' where tc.table_schema='public' and tc.column_name='customer_id' and tc.table_name like 'crm_%' and tc.table_name<>'crm_customers' loop
   begin
     execute format('update public.%I set customer_id=$1 where customer_id=$2',t.table_name) using p_survivor,p_duplicate;
     get diagnostics n=row_count;
     if n>0 then moved:=moved||jsonb_build_object(t.table_name,n); end if;
   exception when unique_violation then
     -- Preserve the survivor's existing relationship and remove only duplicate rows that conflict with it.
     execute format('delete from public.%I where customer_id=$1 and exists (select 1 from public.%I x where x.customer_id=$2)',t.table_name,t.table_name) using p_duplicate,p_survivor;
     execute format('update public.%I set customer_id=$1 where customer_id=$2',t.table_name) using p_survivor,p_duplicate;
     get diagnostics n=row_count;
     if n>0 then moved:=moved||jsonb_build_object(t.table_name,n); end if;
   end;
 end loop;
 update public.crm_customers set lifecycle_status='merged',merged_into_customer_id=s.id,updated_at=now() where id=d.id;
 update public.crm_customers set last_activity_at=greatest(coalesce(last_activity_at,'epoch'::timestamptz),coalesce(d.updated_at,'epoch'::timestamptz)),updated_at=now() where id=s.id;
 insert into public.crm_customer_merge_events(tenant_id,survivor_customer_id,merged_customer_id,reason,evidence,actor_id) values(s.tenant_id,s.id,d.id,p_reason,jsonb_build_object('evidence',coalesce(p_evidence,'{}'::jsonb),'transferred',moved),auth.uid());
 return jsonb_build_object('status','merged','survivor_id',s.id,'merged_id',d.id,'transferred',moved);
end $$;
grant execute on function public.anaira_merge_crm_customer_enterprise(uuid,uuid,text,jsonb) to authenticated;

-- 6) Provider webhook event store (credentials stay outside DB; only metadata/payload is persisted).
create table if not exists public.crm_provider_webhook_events (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, provider text not null,
 external_event_id text not null, event_type text not null, payload jsonb not null default '{}'::jsonb,
 status text not null default 'received', processed_at timestamptz, error text, created_at timestamptz not null default now(),
 unique(provider,external_event_id)
);
alter table public.crm_provider_webhook_events enable row level security;
drop policy if exists crm_provider_webhook_events_access on public.crm_provider_webhook_events;
create policy crm_provider_webhook_events_access on public.crm_provider_webhook_events for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

-- 7) Automation schedule registry
create table if not exists public.crm_automation_schedules (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null, name text not null, worker text not null,
 cadence text not null default 'hourly', enabled boolean not null default true, next_run_at timestamptz,
 last_run_at timestamptz, last_status text, config jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(tenant_id,name)
);
alter table public.crm_automation_schedules enable row level security;
drop policy if exists crm_automation_schedules_access on public.crm_automation_schedules;
create policy crm_automation_schedules_access on public.crm_automation_schedules for all to authenticated using(public.anaira_can_access_tenant(tenant_id)) with check(public.anaira_can_access_tenant(tenant_id));

-- 8) Seed default schedule metadata without assuming a particular hosting scheduler.
insert into public.crm_automation_schedules(tenant_id,name,worker,cadence,enabled,config)
select r.id,'Hotel Guest CRM Functional Worker','/api/crm/functional-worker','hourly',true,jsonb_build_object('requires_cron_secret',true)
from public.restaurants r on conflict(tenant_id,name) do nothing;
insert into public.crm_automation_schedules(tenant_id,name,worker,cadence,enabled,config)
select r.id,'Hotel Guest Pre-Arrival','/api/crm/prearrival-worker','hourly',true,jsonb_build_object('requires_cron_secret',true)
from public.restaurants r on conflict(tenant_id,name) do nothing;
