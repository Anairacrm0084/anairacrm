-- 20261001_restaurant_crm_property_runtime.sql
-- Restaurant CRM property-scoped runtime. Keeps Restaurant SaaS/POS as source of truth.

alter table public.crm_restaurant_visits add column if not exists property_id uuid;
alter table public.crm_restaurant_customer_metrics add column if not exists property_id uuid;
alter table public.crm_bills add column if not exists property_id uuid;

create index if not exists crm_restaurant_visits_property_idx
  on public.crm_restaurant_visits(tenant_id,property_id,visit_at desc);
create index if not exists crm_restaurant_customer_metrics_property_idx
  on public.crm_restaurant_customer_metrics(tenant_id,property_id,customer_id);

-- Recover property from the canonical customer where possible.
update public.crm_restaurant_visits v
set property_id=c.property_id
from public.crm_customers c
where c.id=v.customer_id and c.tenant_id=v.tenant_id and v.property_id is null and c.property_id is not null;

update public.crm_bills b
set property_id=c.property_id
from public.crm_customers c
where c.id=b.customer_id and c.tenant_id=b.tenant_id and b.property_id is null and c.property_id is not null;

update public.crm_restaurant_customer_metrics m
set property_id=c.property_id
from public.crm_customers c
where c.id=m.customer_id and c.tenant_id=m.tenant_id and m.property_id is null and c.property_id is not null;

-- If metrics already contain data, do not silently merge two properties.
do $$
begin
 if exists(
   select 1 from public.crm_restaurant_customer_metrics
   where property_id is null
 ) then
   raise notice 'Restaurant CRM metrics without property_id remain unassigned; they will not be shown in property-scoped CRM.';
 end if;
end $$;

-- Property-aware visit sync. Existing one-argument function is retained for compatibility.
create or replace function public.anaira_sync_restaurant_visit_from_bill(p_bill_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public,pg_temp
as $function$
declare
 b public.crm_bills%rowtype;
 v_id uuid;
 visit_customer uuid;
 visit_amount numeric;
 visit_time timestamptz;
 visit_property uuid;
begin
 select * into b from public.crm_bills where id=p_bill_id for update;
 if not found then raise exception 'Bill not found'; end if;

 visit_customer := b.customer_id;
 if visit_customer is null then return null; end if;

 select coalesce(b.property_id,c.property_id) into visit_property
 from public.crm_customers c
 where c.id=visit_customer and c.tenant_id=b.tenant_id;

 if visit_property is null then
   raise exception 'Restaurant CRM property context is required for bill %',p_bill_id;
 end if;

 if b.property_id is null then
   update public.crm_bills set property_id=visit_property where id=b.id;
 end if;

 select id into v_id
 from public.crm_restaurant_visits
 where tenant_id=b.tenant_id and order_id=b.source_id
   and property_id=visit_property
 limit 1 for update;

 visit_amount := coalesce(b.total,0);
 visit_time := coalesce(b.closed_at,b.created_at);

 if v_id is null then
   insert into public.crm_restaurant_visits
     (tenant_id,property_id,customer_id,visit_at,order_id,amount,payment_method)
   values
     (b.tenant_id,visit_property,visit_customer,visit_time,b.source_id,visit_amount,
      case when b.paid>0 then 'settled' else null end)
   returning id into v_id;
 else
   update public.crm_restaurant_visits
   set customer_id=visit_customer,visit_at=visit_time,amount=visit_amount,
       payment_method=case when b.paid>0 then coalesce(payment_method,'settled') else payment_method end
   where id=v_id;
 end if;

 -- Refresh the canonical restaurant customer metrics for this property.
 insert into public.crm_restaurant_customer_metrics
   (tenant_id,property_id,customer_id,total_visits,lifetime_spend,average_bill,last_visit_at)
 select b.tenant_id,visit_property,visit_customer,count(*),coalesce(sum(amount),0),
        coalesce(avg(amount),0),max(visit_at)
 from public.crm_restaurant_visits
 where tenant_id=b.tenant_id and property_id=visit_property and customer_id=visit_customer
 group by tenant_id,property_id,customer_id
 on conflict (tenant_id,customer_id) do update
 set property_id=excluded.property_id,total_visits=excluded.total_visits,
     lifetime_spend=excluded.lifetime_spend,average_bill=excluded.average_bill,
     last_visit_at=excluded.last_visit_at,updated_at=now();

 update public.crm_customers c
 set property_id=coalesce(c.property_id,visit_property),
     total_restaurant_revenue=coalesce((select sum(rv.amount) from public.crm_restaurant_visits rv where rv.tenant_id=b.tenant_id and rv.property_id=visit_property and rv.customer_id=visit_customer),0),
     total_restaurant_visits=coalesce((select count(*) from public.crm_restaurant_visits rv where rv.tenant_id=b.tenant_id and rv.property_id=visit_property and rv.customer_id=visit_customer),0),
     updated_at=now()
 where c.id=visit_customer and c.tenant_id=b.tenant_id;

 return v_id;
end
$function$;

revoke execute on function public.anaira_sync_restaurant_visit_from_bill(uuid) from anon;
grant execute on function public.anaira_sync_restaurant_visit_from_bill(uuid) to authenticated;

-- Keep the close-bill lifecycle real and property-aware.
create or replace function public.anaira_close_crm_bill(p_bill_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $function$
declare b public.crm_bills%rowtype; v uuid;
begin
 select * into b from public.crm_bills where id=p_bill_id for update;
 if not found then raise exception 'Bill not found'; end if;
 if coalesce(b.paid,0) < coalesce(b.total,0) then raise exception 'Bill is not fully paid'; end if;
 update public.crm_bills set status='paid',closed_at=coalesce(closed_at,now()) where id=b.id;
 v := public.anaira_sync_restaurant_visit_from_bill(b.id);
 return jsonb_build_object('ok',true,'bill_id',b.id,'restaurant_visit_id',v,'property_id',(select property_id from public.crm_restaurant_visits where id=v));
end
$function$;

revoke execute on function public.anaira_close_crm_bill(uuid) from anon;
grant execute on function public.anaira_close_crm_bill(uuid) to authenticated;
