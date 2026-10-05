-- ANAIRA HOTEL GUEST CRM FINAL COMPLETION FIX
-- Repairs the missing dependency that caused: relation public.crm_customer_merge_events does not exist.
-- This migration is idempotent and is safe to keep in source control.

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
create index if not exists crm_customer_merge_events_tenant_idx on public.crm_customer_merge_events(tenant_id,created_at desc);
create index if not exists crm_customer_merge_events_survivor_idx on public.crm_customer_merge_events(tenant_id,survivor_customer_id,created_at desc);
create index if not exists crm_customer_merge_events_merged_idx on public.crm_customer_merge_events(tenant_id,merged_customer_id,created_at desc);
alter table public.crm_customer_merge_events enable row level security;
drop policy if exists crm_customer_merge_events_tenant on public.crm_customer_merge_events;
create policy crm_customer_merge_events_tenant on public.crm_customer_merge_events
for all to authenticated using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));

-- 101: Hotel Guest CRM final enterprise completion
-- Cross-selling opportunities, unified timeline materialization, source linkage,
-- permission catalog, and tenant-safe operational helpers.

create table if not exists public.crm_consent_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  consent_id uuid references public.crm_consents(id) on delete set null,
  channel text not null,
  purpose text not null,
  status text not null,
  source text,
  captured_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index if not exists crm_consent_events_tenant_idx on public.crm_consent_events(tenant_id,customer_id,created_at desc);
alter table public.crm_consent_events enable row level security;
drop policy if exists crm_consent_events_tenant on public.crm_consent_events;
create policy crm_consent_events_tenant on public.crm_consent_events
for all to authenticated using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));

create or replace function public.anaira_capture_consent_history()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare t uuid;
begin
  select tenant_id into t from public.crm_customers where id=new.customer_id;
  if t is not null then
    insert into public.crm_consent_events(tenant_id,customer_id,consent_id,channel,purpose,status,source,captured_at)
    values(t,new.customer_id,new.id,new.channel,new.purpose,new.status,new.source,coalesce(new.captured_at,now()));
  end if;
  return new;
end $$;
drop trigger if exists trg_hgc_consent_history on public.crm_consents;
create trigger trg_hgc_consent_history after insert or update on public.crm_consents
for each row execute function public.anaira_capture_consent_history();

create table if not exists public.crm_hotel_cross_sell_opportunities (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid not null references public.crm_customers(id) on delete cascade,
  stay_id uuid references public.crm_guest_stays(id) on delete set null,
  rule_id uuid references public.crm_cross_sell_rules(id) on delete set null,
  source_context text not null default 'hotel_guest',
  target_product text not null,
  offer_name text not null,
  amount numeric(14,2) not null default 0,
  status text not null default 'proposed',
  sent_at timestamptz,
  accepted_at timestamptz,
  declined_at timestamptz,
  expired_at timestamptz,
  revenue numeric(14,2) not null default 0,
  source text not null default 'manual',
  eligibility jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists crm_hotel_cross_sell_tenant_status_idx
  on public.crm_hotel_cross_sell_opportunities(tenant_id,status,created_at desc);
create index if not exists crm_hotel_cross_sell_customer_idx
  on public.crm_hotel_cross_sell_opportunities(tenant_id,customer_id,created_at desc);

alter table public.crm_hotel_cross_sell_opportunities enable row level security;
drop policy if exists crm_hotel_cross_sell_tenant on public.crm_hotel_cross_sell_opportunities;
create policy crm_hotel_cross_sell_tenant on public.crm_hotel_cross_sell_opportunities
for all to authenticated
using (public.anaira_can_access_tenant(tenant_id))
with check (public.anaira_can_access_tenant(tenant_id));

-- Canonical timeline uniqueness. Existing rows remain intact.
-- Remove duplicate source events before enforcing the canonical unique key.
delete from public.crm_timeline_events a
using public.crm_timeline_events b
where a.id>b.id
  and a.tenant_id=b.tenant_id
  and a.source_system=b.source_system
  and a.source_id=b.source_id
  and a.event_type=b.event_type
  and a.source_id is not null;

create unique index if not exists crm_timeline_source_event_uq
  on public.crm_timeline_events(tenant_id,source_system,source_id,event_type);

-- Record/update a canonical omnichannel timeline event.
create or replace function public.anaira_record_hotel_guest_timeline(
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
  if p_tenant_id is null or p_customer_id is null then return null; end if;
  insert into public.crm_timeline_events(
    tenant_id,customer_id,event_type,source_system,source_id,title,description,
    amount,metadata,occurred_at,created_at
  ) values (
    p_tenant_id,p_customer_id,p_event_type,p_source_system,p_source_id,p_title,
    p_description,p_amount,coalesce(p_metadata,'{}'::jsonb),coalesce(p_occurred_at,now()),now()
  )
  on conflict (tenant_id,source_system,source_id,event_type)
  do update set
    title=excluded.title,
    description=excluded.description,
    amount=excluded.amount,
    metadata=excluded.metadata,
    occurred_at=excluded.occurred_at
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.anaira_record_hotel_guest_timeline(uuid,uuid,text,text,text,text,text,numeric,jsonb,timestamptz) from public;
grant execute on function public.anaira_record_hotel_guest_timeline(uuid,uuid,text,text,text,text,text,numeric,jsonb,timestamptz) to authenticated;

-- Generic trigger for relationship-layer tables. It intentionally records
-- relationship events only; operational masters remain Booking Engine/PMS/POS.
create or replace function public.anaira_hotel_guest_timeline_trigger()
returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare
  j jsonb := to_jsonb(new);
  v_tenant uuid;
  v_customer uuid;
  v_source text;
  v_type text;
  v_title text;
  v_desc text;
  v_amount numeric;
  v_when timestamptz;
  v_status text;
begin
  v_tenant := nullif(j->>'tenant_id','')::uuid;
  v_customer := nullif(j->>'customer_id','')::uuid;
  if v_customer is null and tg_table_name='crm_customer_merge_events' then
    v_customer := nullif(j->>'survivor_customer_id','')::uuid;
  end if;
  if v_customer is null and tg_table_name='crm_loyalty_transactions' then
    select a.customer_id into v_customer
    from public.crm_loyalty_accounts a
    where a.id=nullif(j->>'loyalty_account_id','')::uuid;
    if v_tenant is null then
      select a.tenant_id into v_tenant
      from public.crm_loyalty_accounts a
      where a.id=nullif(j->>'loyalty_account_id','')::uuid;
    end if;
  end if;
  if v_customer is null or v_tenant is null then return new; end if;

  v_status := coalesce(j->>'status','');
  v_source := case
    when tg_table_name like 'booking_reservations' then 'booking_engine'
    when tg_table_name like 'pms_%' then 'pms'
    when tg_table_name='crm_guest_stay_events' then coalesce(j->>'source','pms')
    when tg_table_name='crm_interactions' then coalesce(j->>'channel','crm')
    when tg_table_name='crm_restaurant_visits' then 'restaurant_pos'
    else 'crm'
  end;
  v_type := case
    when tg_table_name='crm_guest_stays' then 'stay'
    when tg_table_name='crm_guest_requests' then 'guest_request'
    when tg_table_name='crm_complaints' then 'complaint'
    when tg_table_name='crm_feedback' then 'feedback'
    when tg_table_name='crm_guest_upsells' then 'upsell'
    when tg_table_name='crm_hotel_cross_sell_opportunities' then 'cross_sell'
    when tg_table_name='crm_interactions' then 'communication'
    when tg_table_name='crm_restaurant_visits' then 'restaurant_visit'
    when tg_table_name='crm_customer_preferences' then 'preference'
    when tg_table_name='crm_consents' then 'consent'
    when tg_table_name='crm_tasks' then 'task'
    when tg_table_name='crm_guest_documents' then 'document'
    when tg_table_name='crm_guest_precheckins' then 'precheckin'
    when tg_table_name='crm_guest_stay_events' then coalesce(j->>'event_type','stay_event')
    when tg_table_name='crm_ai_insights' then 'ai_insight'
    when tg_table_name='crm_ai_action_queue' then 'ai_action'
    when tg_table_name='crm_customer_merge_events' then 'merge'
    when tg_table_name='crm_loyalty_transactions' then 'loyalty'
    else replace(tg_table_name,'crm_','')
  end;
  v_title := coalesce(
    j->>'title',j->>'offer_name',j->>'subject',j->>'document_type',
    j->>'event_type',j->>'request_type',j->>'name',j->>'insight_type',
    initcap(replace(tg_table_name,'crm_',' '))
  );
  v_desc := coalesce(j->>'description',j->>'notes',j->>'comment',j->>'summary',j->>'resolution');
  v_amount := coalesce(
    nullif(j->>'revenue','')::numeric,
    nullif(j->>'amount','')::numeric,
    nullif(j->>'total_amount','')::numeric
  );
  v_when := coalesce(
    nullif(j->>'occurred_at','')::timestamptz,
    nullif(j->>'requested_at','')::timestamptz,
    nullif(j->>'opened_at','')::timestamptz,
    nullif(j->>'offered_at','')::timestamptz,
    nullif(j->>'captured_at','')::timestamptz,
    nullif(j->>'created_at','')::timestamptz,
    now()
  );

  perform public.anaira_record_hotel_guest_timeline(
    v_tenant,v_customer,v_type,v_source,
    coalesce(j->>'id',md5(j::text)),
    v_title,
    case when v_status<>'' then coalesce(v_desc,'')||' · '||v_status else v_desc end,
    v_amount,j,v_when
  );
  return new;
exception when others then
  -- Timeline must never block the operational transaction.
  return new;
end $$;

-- Relationship-layer event triggers.
drop trigger if exists trg_hgc_timeline_stays on public.crm_guest_stays;
create trigger trg_hgc_timeline_stays after insert or update on public.crm_guest_stays
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_requests on public.crm_guest_requests;
create trigger trg_hgc_timeline_requests after insert or update on public.crm_guest_requests
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_complaints on public.crm_complaints;
create trigger trg_hgc_timeline_complaints after insert or update on public.crm_complaints
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_feedback on public.crm_feedback;
create trigger trg_hgc_timeline_feedback after insert or update on public.crm_feedback
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_upsells on public.crm_guest_upsells;
create trigger trg_hgc_timeline_upsells after insert or update on public.crm_guest_upsells
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_reviews on public.crm_review_requests;
create trigger trg_hgc_timeline_reviews after insert or update on public.crm_review_requests
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_recovery on public.crm_service_recovery;
create trigger trg_hgc_timeline_recovery after insert or update on public.crm_service_recovery
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_cross_sell on public.crm_hotel_cross_sell_opportunities;
create trigger trg_hgc_timeline_cross_sell after insert or update on public.crm_hotel_cross_sell_opportunities
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_interactions on public.crm_interactions;
create trigger trg_hgc_timeline_interactions after insert or update on public.crm_interactions
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_restaurant on public.crm_restaurant_visits;
create trigger trg_hgc_timeline_restaurant after insert or update on public.crm_restaurant_visits
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_preferences on public.crm_customer_preferences;
create trigger trg_hgc_timeline_preferences after insert or update on public.crm_customer_preferences
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_consents on public.crm_consents;
create trigger trg_hgc_timeline_consents after insert or update on public.crm_consents
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_consent_events on public.crm_consent_events;
create trigger trg_hgc_timeline_consent_events after insert on public.crm_consent_events
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_tasks on public.crm_tasks;
create trigger trg_hgc_timeline_tasks after insert or update on public.crm_tasks
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_documents on public.crm_guest_documents;
create trigger trg_hgc_timeline_documents after insert or update on public.crm_guest_documents
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_precheckins on public.crm_guest_precheckins;
create trigger trg_hgc_timeline_precheckins after insert or update on public.crm_guest_precheckins
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_stay_events on public.crm_guest_stay_events;
create trigger trg_hgc_timeline_stay_events after insert or update on public.crm_guest_stay_events
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_ai on public.crm_ai_insights;
create trigger trg_hgc_timeline_ai after insert or update on public.crm_ai_insights
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_ai_queue on public.crm_ai_action_queue;
create trigger trg_hgc_timeline_ai_queue after insert or update on public.crm_ai_action_queue
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_merge on public.crm_customer_merge_events;
create trigger trg_hgc_timeline_merge after insert or update on public.crm_customer_merge_events
for each row execute function public.anaira_hotel_guest_timeline_trigger();

drop trigger if exists trg_hgc_timeline_loyalty on public.crm_loyalty_transactions;
create trigger trg_hgc_timeline_loyalty after insert or update on public.crm_loyalty_transactions
for each row execute function public.anaira_hotel_guest_timeline_trigger();

-- Backfill the canonical timeline for existing CRM data. Duplicate-safe.
insert into public.crm_timeline_events
  (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,metadata,occurred_at)
select s.tenant_id,s.customer_id,'stay','crm',s.id::text,
       'Stay: '||coalesce(s.booking_status,'unknown'),
       coalesce(s.room_number,'Room')||' · '||coalesce(s.booking_source,'unknown'),
       s.total_amount,
       jsonb_build_object('stay_id',s.id),
       coalesce(s.check_in_date::timestamptz,s.created_at)
from public.crm_guest_stays s
where s.customer_id is not null
on conflict (tenant_id,source_system,source_id,event_type) do nothing;

insert into public.crm_timeline_events
  (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
select r.tenant_id,r.customer_id,'guest_request','crm',r.id::text,
       coalesce(r.request_type,'Guest Request'),
       coalesce(r.description,'')||' · '||coalesce(r.status,'open'),
       coalesce(r.requested_at,now())
from public.crm_guest_requests r
where r.customer_id is not null
on conflict (tenant_id,source_system,source_id,event_type) do nothing;

insert into public.crm_timeline_events
  (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,occurred_at)
select c.tenant_id,c.customer_id,'complaint','crm',c.id::text,c.title,
       coalesce(c.description,'')||' · '||coalesce(c.status,'open'),
       c.compensation,coalesce(c.opened_at,now())
from public.crm_complaints c
where c.customer_id is not null
on conflict (tenant_id,source_system,source_id,event_type) do nothing;

insert into public.crm_timeline_events
  (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,occurred_at)
select f.tenant_id,f.customer_id,'feedback','crm',f.id::text,
       'Guest Feedback',
       coalesce(f.comment,'Rating '||coalesce(f.overall_rating::text,'—')),
       f.overall_rating,
       coalesce(f.created_at,now())
from public.crm_feedback f
where f.customer_id is not null
on conflict (tenant_id,source_system,source_id,event_type) do nothing;


-- Rebuild/backfill the canonical timeline for one tenant. It is idempotent and
-- safe to run after source synchronization.
create or replace function public.anaira_rebuild_hotel_guest_timeline(p_tenant_id uuid)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare n integer := 0;
begin
  if auth.uid() is not null and not public.anaira_can_access_tenant(p_tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,metadata,occurred_at)
  select s.tenant_id,s.customer_id,'stay','booking_engine',s.id::text,
         'Stay · '||coalesce(s.booking_status,'unknown'),
         coalesce(s.room_number,'Room')||' · '||coalesce(s.booking_source,'unknown'),
         s.total_amount,jsonb_build_object('stay_id',s.id),coalesce(s.check_in_date::timestamptz,s.created_at)
  from public.crm_guest_stays s
  where s.tenant_id=p_tenant_id and s.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,amount=excluded.amount,
    metadata=excluded.metadata,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select r.tenant_id,r.customer_id,'guest_request','crm',r.id::text,
         coalesce(r.request_type,'Guest Request'),
         coalesce(r.description,'')||' · '||coalesce(r.status,'open'),coalesce(r.requested_at,now())
  from public.crm_guest_requests r
  where r.tenant_id=p_tenant_id and r.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,occurred_at)
  select c.tenant_id,c.customer_id,'complaint','crm',c.id::text,c.title,
         coalesce(c.description,'')||' · '||coalesce(c.status,'open'),c.compensation,coalesce(c.opened_at,now())
  from public.crm_complaints c
  where c.tenant_id=p_tenant_id and c.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,amount=excluded.amount,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,occurred_at)
  select u.tenant_id,u.customer_id,'upsell','crm',u.id::text,u.offer_name,
         coalesce(u.offer_type,'service')||' · '||coalesce(u.status,'offered'),u.amount,coalesce(u.offered_at,now())
  from public.crm_guest_upsells u
  where u.tenant_id=p_tenant_id and u.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,amount=excluded.amount,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,occurred_at)
  select x.tenant_id,x.customer_id,'cross_sell','crm',x.id::text,x.offer_name,
         coalesce(x.target_product,'service')||' · '||coalesce(x.status,'proposed'),x.revenue,coalesce(x.sent_at,x.created_at)
  from public.crm_hotel_cross_sell_opportunities x
  where x.tenant_id=p_tenant_id
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,amount=excluded.amount,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select c.tenant_id,c.id,'communication','crm',i.id::text,
         coalesce(i.subject,i.interaction_type),coalesce(i.notes,'')||' · '||coalesce(i.channel,'internal'),
         coalesce(i.occurred_at,i.created_at)
  from public.crm_interactions i
  join public.crm_customers c on c.id=i.customer_id
  where c.tenant_id=p_tenant_id
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select c.tenant_id,c.customer_id,'feedback','crm',f.id::text,'Guest Feedback',
         coalesce(f.comment,'Rating '||coalesce(f.overall_rating::text,'—')),coalesce(f.created_at,now())
  from public.crm_feedback f
  join public.crm_customers c on c.id=f.customer_id
  where c.tenant_id=p_tenant_id
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,occurred_at)
  select v.tenant_id,v.customer_id,'restaurant_visit','restaurant_pos',v.id::text,
         'Restaurant Visit',coalesce(v.payment_method,'POS')||' · '||coalesce(v.guest_count,1)::text||' guests',
         v.amount,coalesce(v.visit_at,now())
  from public.crm_restaurant_visits v
  where v.tenant_id=p_tenant_id and v.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,amount=excluded.amount,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select r.tenant_id,r.customer_id,'review_request','reputation',r.id::text,
         'Review Request · '||r.channel,coalesce(r.status,'pending'),coalesce(r.requested_at,now())
  from public.crm_review_requests r
  where r.tenant_id=p_tenant_id and r.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,occurred_at)
  select r.tenant_id,r.customer_id,'service_recovery','reputation',r.id::text,
         'Service Recovery · '||coalesce(r.recovery_type,'recovery'),coalesce(r.status,'proposed'),
         r.value,coalesce(r.created_at,now())
  from public.crm_service_recovery r
  where r.tenant_id=p_tenant_id and r.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,amount=excluded.amount,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select a.tenant_id,a.customer_id,'loyalty','crm',t.id::text,'Loyalty · '||t.transaction_type,
         coalesce(t.notes,'Points: '||t.points::text),coalesce(t.created_at,now())
  from public.crm_loyalty_transactions t
  join public.crm_loyalty_accounts a on a.id=t.loyalty_account_id
  where a.tenant_id=p_tenant_id and a.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select t.tenant_id,t.customer_id,'task','crm',t.id::text,t.title,
         coalesce(t.status,'open')||' · '||coalesce(t.priority,'normal'),coalesce(t.created_at,now())
  from public.crm_tasks t
  where t.tenant_id=p_tenant_id and t.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select d.tenant_id,d.customer_id,'document','crm',d.id::text,'Document · '||d.document_type,
         coalesce(d.verification_status,'pending'),coalesce(d.created_at,now())
  from public.crm_guest_documents d
  where d.tenant_id=p_tenant_id and d.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select p.tenant_id,p.customer_id,'precheckin','crm',p.id::text,'Pre-check-in',
         coalesce(p.status,'not_started'),coalesce(p.created_at,now())
  from public.crm_guest_precheckins p
  where p.tenant_id=p_tenant_id and p.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select e.tenant_id,e.customer_id,'stay_event',coalesce(e.source,'crm'),e.id::text,
         coalesce(e.event_type,'stay event'),coalesce(e.payload->>'notes',''),coalesce(e.created_at,now())
  from public.crm_guest_stay_events e
  where e.tenant_id=p_tenant_id and e.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select i.tenant_id,i.customer_id,'ai_insight','ai',i.id::text,
         coalesce(i.insight_type,'AI insight'),coalesce(i.summary,i.recommendation,''),coalesce(i.created_at,now())
  from public.crm_ai_insights i
  where i.tenant_id=p_tenant_id and i.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select q.tenant_id,q.customer_id,'ai_action','ai',q.id::text,
         coalesce(q.action_type,'AI action'),coalesce(q.status,'pending_approval'),coalesce(q.created_at,now())
  from public.crm_ai_action_queue q
  where q.tenant_id=p_tenant_id and q.customer_id is not null
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  insert into public.crm_timeline_events
    (tenant_id,customer_id,event_type,source_system,source_id,title,description,occurred_at)
  select m.tenant_id,m.survivor_customer_id,'merge','crm',m.id::text,
         'Guest profile merged','Merged duplicate guest into survivor',coalesce(m.created_at,now())
  from public.crm_customer_merge_events m
  where m.tenant_id=p_tenant_id
  on conflict (tenant_id,source_system,source_id,event_type) do update set
    title=excluded.title,description=excluded.description,occurred_at=excluded.occurred_at;

  select count(*) into n from public.crm_timeline_events where tenant_id=p_tenant_id;
  return n;
end $$;
revoke all on function public.anaira_rebuild_hotel_guest_timeline(uuid) from public;
grant execute on function public.anaira_rebuild_hotel_guest_timeline(uuid) to authenticated;

-- Two-argument, tenant-scoped pre-arrival queue RPC. The legacy one-argument
-- function remains available for trusted server jobs.
create or replace function public.anaira_queue_prearrival_jobs(p_tenant_id uuid,p_now timestamptz default now())
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare n int;
begin
  if not public.anaira_can_access_tenant(p_tenant_id) then
    raise exception 'TENANT_ACCESS_DENIED';
  end if;
  insert into public.crm_prearrival_jobs(tenant_id,customer_id,guest_stay_id,job_type,due_at,channel,payload)
  select s.tenant_id,s.customer_id,s.id,'prearrival_7d',
         greatest(p_now,s.check_in_date::timestamptz-interval '7 days'),'whatsapp',
         jsonb_build_object('booking',s.external_booking_id)
  from public.crm_guest_stays s
  where s.tenant_id=p_tenant_id
    and s.booking_status='confirmed'
    and s.check_in_date>=p_now::date
    and s.check_in_date<=p_now::date+30
  on conflict do nothing;
  get diagnostics n=row_count;
  return n;
end $$;
revoke all on function public.anaira_queue_prearrival_jobs(uuid,timestamptz) from public;
grant execute on function public.anaira_queue_prearrival_jobs(uuid,timestamptz) to authenticated;

-- Storage policies must also allow Super Admin property switching while keeping
-- every document path tenant-prefixed.
drop policy if exists crm_guest_docs_select on storage.objects;
create policy crm_guest_docs_select on storage.objects for select to authenticated
using (bucket_id='crm-guest-documents' and ((storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text or public.anaira_current_is_super_admin()));

drop policy if exists crm_guest_docs_insert on storage.objects;
create policy crm_guest_docs_insert on storage.objects for insert to authenticated
with check (bucket_id='crm-guest-documents' and ((storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text or public.anaira_current_is_super_admin()));

drop policy if exists crm_guest_docs_update on storage.objects;
create policy crm_guest_docs_update on storage.objects for update to authenticated
using (bucket_id='crm-guest-documents' and ((storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text or public.anaira_current_is_super_admin()))
with check (bucket_id='crm-guest-documents' and ((storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text or public.anaira_current_is_super_admin()));

drop policy if exists crm_guest_docs_delete on storage.objects;
create policy crm_guest_docs_delete on storage.objects for delete to authenticated
using (bucket_id='crm-guest-documents' and ((storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text or public.anaira_current_is_super_admin()));

-- Dedicated Hotel Guest CRM permissions.
insert into public.anaira_permissions(permission_key,name,module,description) values
('hotel_guest_crm.view','View Hotel Guest CRM','hotel-guest-crm','Access the Hotel Guest CRM workspace'),
('hotel_guest_crm.manage','Manage Hotel Guest CRM','hotel-guest-crm','Create and update Hotel Guest CRM relationship records'),
('hotel_guest_crm.configure','Configure Hotel Guest CRM','hotel-guest-crm','Configure Hotel Guest CRM automation, security and integrations'),
('cross_selling.view','View Cross-selling','hotel-guest-crm','View guest cross-sell opportunities'),
('cross_selling.manage','Manage Cross-selling','hotel-guest-crm','Create/update/send guest cross-sell offers'),
('cross_selling.configure','Configure Cross-selling','hotel-guest-crm','Configure cross-sell rules')
on conflict(permission_key) do update set name=excluded.name,module=excluded.module,description=excluded.description;

insert into public.anaira_role_permissions(role_key,permission_key)
select r.role_key,p.permission_key
from public.anaira_roles r cross join public.anaira_permissions p
where r.role_key in ('admin','manager') and p.permission_key in (
'hotel_guest_crm.view','hotel_guest_crm.manage','hotel_guest_crm.configure',
'cross_selling.view','cross_selling.manage','cross_selling.configure'
) on conflict do nothing;

-- Rebuild canonical tenant policies for CRM relationship tables that have an
-- explicit tenant/customer ownership column. This removes any historical
-- authenticated USING(true) policy from the Hotel Guest CRM domain.
do $$
declare r record; pol record; expr text;
begin
  for r in
    select table_name from information_schema.tables
    where table_schema='public' and table_type='BASE TABLE'
      and table_name like 'crm_%'
      and table_name not like 'crm_seo_%'
  loop
    if exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='tenant_id') then
      expr := format('public.anaira_can_access_tenant(%I.tenant_id)',r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='corporate_account_id') then
      expr := format('(exists(select 1 from public.crm_corporate_accounts c where c.id=%I.corporate_account_id and public.anaira_can_access_tenant(c.tenant_id)))',r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='event_id') then
      expr := format('(exists(select 1 from public.crm_events e where e.id=%I.event_id and public.anaira_can_access_tenant(e.tenant_id)))',r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='campaign_id') then
      expr := format('(exists(select 1 from public.crm_campaigns c where c.id=%I.campaign_id and public.anaira_can_access_tenant(c.tenant_id)))',r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='loyalty_account_id') then
      expr := format('(exists(select 1 from public.crm_loyalty_accounts a where a.id=%I.loyalty_account_id and public.anaira_can_access_tenant(a.tenant_id)))',r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='customer_id') then
      expr := format('(exists(select 1 from public.crm_customers c where c.id=%I.customer_id and public.anaira_can_access_tenant(c.tenant_id)))',r.table_name);
    else
      continue;
    end if;
    for pol in select policyname from pg_policies where schemaname='public' and tablename=r.table_name loop
      execute format('drop policy if exists %I on public.%I',pol.policyname,r.table_name);
    end loop;
    execute format('create policy %I on public.%I for all to authenticated using (%s) with check (%s)',
      'crm_hgc_canonical_access',r.table_name,expr,expr);
  end loop;
end $$;
