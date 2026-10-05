-- Restaurant CRM + Customer 360 property-scoped runtime closure.
do $$
begin
  if exists (select 1 from pg_constraint where conrelid='public.crm_restaurant_customer_metrics'::regclass and contype='p' and conname='crm_restaurant_customer_metrics_pkey') then
    alter table public.crm_restaurant_customer_metrics drop constraint crm_restaurant_customer_metrics_pkey;
  end if;
exception when undefined_table then null;
end $$;
create unique index if not exists crm_restaurant_customer_metrics_tenant_property_customer_uidx on public.crm_restaurant_customer_metrics(tenant_id,property_id,customer_id);
create index if not exists crm_restaurant_visits_tenant_property_idx on public.crm_restaurant_visits(tenant_id,property_id,visit_at desc);
create index if not exists crm_bills_tenant_property_idx on public.crm_bills(tenant_id,property_id,created_at desc);

create or replace function public.anaira_sync_restaurant_visit_from_bill(p_bill_id uuid)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $$
declare b public.crm_bills%rowtype; v_id uuid; visit_property uuid;
begin
 select * into b from public.crm_bills where id=p_bill_id for update;
 if not found then raise exception 'Bill not found'; end if;
 if b.customer_id is null then return null; end if;
 select coalesce(b.property_id,c.property_id) into visit_property from public.crm_customers c where c.id=b.customer_id and c.tenant_id=b.tenant_id;
 if visit_property is null then raise exception 'Restaurant CRM property context is required'; end if;
 update public.crm_bills set property_id=visit_property where id=b.id and property_id is distinct from visit_property;
 select id into v_id from public.crm_restaurant_visits where tenant_id=b.tenant_id and property_id=visit_property and order_id=b.source_id limit 1 for update;
 if v_id is null then
   insert into public.crm_restaurant_visits(tenant_id,property_id,customer_id,visit_at,order_id,amount,payment_method)
   values(b.tenant_id,visit_property,b.customer_id,coalesce(b.closed_at,b.created_at),b.source_id,coalesce(b.total,0),case when coalesce(b.paid,0)>0 then 'settled' else null end)
   returning id into v_id;
 end if;
 insert into public.crm_restaurant_customer_metrics(tenant_id,property_id,customer_id,total_visits,lifetime_spend,average_bill,last_visit_at)
 select b.tenant_id,visit_property,b.customer_id,count(*),coalesce(sum(amount),0),coalesce(avg(amount),0),max(visit_at)
 from public.crm_restaurant_visits where tenant_id=b.tenant_id and property_id=visit_property and customer_id=b.customer_id
 group by tenant_id,property_id,customer_id
 on conflict (tenant_id,property_id,customer_id) do update set total_visits=excluded.total_visits,lifetime_spend=excluded.lifetime_spend,average_bill=excluded.average_bill,last_visit_at=excluded.last_visit_at,updated_at=now();
 return v_id;
end $$;
revoke execute on function public.anaira_sync_restaurant_visit_from_bill(uuid) from anon;
grant execute on function public.anaira_sync_restaurant_visit_from_bill(uuid) to authenticated;
