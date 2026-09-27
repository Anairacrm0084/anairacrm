-- Phase 42: Leads CRM state machine and conversion contract
alter table public.crm_leads add column if not exists qualified_at timestamptz;
alter table public.crm_leads add column if not exists converted_at timestamptz;
alter table public.crm_leads add column if not exists lost_at timestamptz;
alter table public.crm_leads add column if not exists lost_reason text;
create table if not exists public.crm_lead_stage_history(
 id uuid primary key default gen_random_uuid(), tenant_id uuid, lead_id uuid not null references public.crm_leads(id) on delete cascade,
 from_stage text, to_stage text not null, reason text, changed_by uuid, changed_at timestamptz not null default now());
alter table public.crm_lead_stage_history enable row level security;
drop policy if exists tenant_access on public.crm_lead_stage_history;
create policy tenant_access on public.crm_lead_stage_history for all to authenticated using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create index if not exists crm_leads_tenant_stage_followup_idx on public.crm_leads(tenant_id,stage,next_follow_up);
create index if not exists crm_lead_stage_history_lead_idx on public.crm_lead_stage_history(tenant_id,lead_id,changed_at desc);
create index if not exists crm_followup_lead_schedule_idx on public.crm_followup_events(tenant_id,lead_id,status,scheduled_at);
create or replace function public.anaira_lead_transition(p_lead_id uuid,p_to_stage text,p_reason text default null,p_follow_up_at timestamptz default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $function$
declare l public.crm_leads%rowtype; old_stage text;
begin select * into l from public.crm_leads where id=p_lead_id for update; if not found then raise exception 'Lead not found'; end if; old_stage:=l.stage;
if p_to_stage not in ('new','contacted','qualified','proposal','negotiation','won','lost') then raise exception 'Invalid lead stage'; end if;
if old_stage=p_to_stage then if p_follow_up_at is not null then update public.crm_leads set next_follow_up=p_follow_up_at where id=l.id; end if; return jsonb_build_object('ok',true,'lead_id',l.id,'stage',l.stage); end if;
if old_stage in ('won','lost') then raise exception 'Closed lead cannot transition from %',old_stage; end if;
if p_to_stage='qualified' then update public.crm_leads set stage='qualified',qualified_at=coalesce(qualified_at,now()),next_follow_up=p_follow_up_at where id=l.id;
elsif p_to_stage='won' then if l.customer_id is null then raise exception 'Lead must have a customer before conversion'; end if; update public.crm_leads set stage='won',converted_at=coalesce(converted_at,now()),next_follow_up=null where id=l.id;
elsif p_to_stage='lost' then update public.crm_leads set stage='lost',lost_at=coalesce(lost_at,now()),lost_reason=coalesce(p_reason,lost_reason),next_follow_up=null where id=l.id;
else update public.crm_leads set stage=p_to_stage,next_follow_up=p_follow_up_at where id=l.id; end if;
insert into public.crm_lead_stage_history(tenant_id,lead_id,from_stage,to_stage,reason,changed_by) values(l.tenant_id,l.id,old_stage,p_to_stage,p_reason,auth.uid());
if p_follow_up_at is not null and p_to_stage not in ('won','lost') then insert into public.crm_followup_events(tenant_id,customer_id,lead_id,scheduled_at,status) values(l.tenant_id,l.customer_id,l.id,p_follow_up_at,'pending'); end if;
return jsonb_build_object('ok',true,'lead_id',l.id,'from_stage',old_stage,'stage',p_to_stage); end $function$;
revoke execute on function public.anaira_lead_transition(uuid,text,text,timestamptz) from anon;
grant execute on function public.anaira_lead_transition(uuid,text,text,timestamptz) to authenticated;
