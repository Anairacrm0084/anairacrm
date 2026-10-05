create or replace function public.anaira_crm_record_action(
  p_tenant_id uuid,p_property_id uuid,p_entity_type text,p_entity_id uuid,p_action text,p_payload jsonb default '{}'::jsonb
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null or not public.anaira_can_access_tenant(p_tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;
 if p_property_id is not null and not exists(select 1 from public.anaira_hospitality_properties_master where id=p_property_id and tenant_id=p_tenant_id) then raise exception 'PROPERTY_ACCESS_DENIED'; end if;
 insert into public.crm_audit_logs(tenant_id,property_id,actor_id,entity_type,entity_id,action,before_data,after_data)
 values(p_tenant_id,p_property_id,auth.uid(),p_entity_type,p_entity_id,p_action,null,coalesce(p_payload,'{}'::jsonb));
 return jsonb_build_object('ok',true,'action',p_action,'entity_id',p_entity_id);
end $$;
revoke all on function public.anaira_crm_record_action(uuid,uuid,text,uuid,text,jsonb) from public,anon;
grant execute on function public.anaira_crm_record_action(uuid,uuid,text,uuid,text,jsonb) to authenticated;

create or replace function public.anaira_record_crm_timeline(
 p_tenant_id uuid,p_customer_id uuid,p_event_type text,p_source_system text,p_source_id text,p_title text,
 p_description text default null,p_amount numeric default null,p_metadata jsonb default '{}'::jsonb,p_occurred_at timestamptz default now()
) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid;
begin
 if auth.uid() is null or p_tenant_id is null or p_customer_id is null then raise exception 'CRM_AUTH_OR_INPUT_REQUIRED'; end if;
 if not public.anaira_can_access_tenant(p_tenant_id) then raise exception 'TENANT_ACCESS_DENIED'; end if;
 if not exists(select 1 from public.crm_customers where id=p_customer_id and tenant_id=p_tenant_id) then raise exception 'CUSTOMER_ACCESS_DENIED'; end if;
 insert into public.crm_timeline_events(tenant_id,customer_id,event_type,source_system,source_id,title,description,amount,metadata,occurred_at,created_at)
 values(p_tenant_id,p_customer_id,p_event_type,p_source_system,p_source_id,p_title,p_description,p_amount,coalesce(p_metadata,'{}'::jsonb),coalesce(p_occurred_at,now()),now())
 on conflict (tenant_id,source_system,source_id,event_type) do update set title=excluded.title,description=excluded.description,amount=excluded.amount,metadata=excluded.metadata,occurred_at=excluded.occurred_at
 returning id into v_id;
 return v_id;
end $$;
revoke all on function public.anaira_record_crm_timeline(uuid,uuid,text,text,text,text,text,numeric,jsonb,timestamptz) from public,anon;
grant execute on function public.anaira_record_crm_timeline(uuid,uuid,text,text,text,text,text,numeric,jsonb,timestamptz) to authenticated;
revoke execute on function public.anaira_sync_loyalty_property() from anon;
