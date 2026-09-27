create unique index if not exists crm_restaurant_visits_order_identity_idx on public.crm_restaurant_visits(tenant_id,order_id) where order_id is not null;

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
begin
 select * into b from public.crm_bills where id=p_bill_id for update;
 if not found then raise exception 'Bill not found'; end if;
 visit_customer := b.customer_id;
 if visit_customer is null then return null; end if;
 select id into v_id from public.crm_restaurant_visits
 where tenant_id=b.tenant_id and order_id=b.source_id
 limit 1 for update;
 visit_amount := coalesce(b.total,0);
 visit_time := coalesce(b.closed_at,b.created_at);
 if v_id is null then
   insert into public.crm_restaurant_visits
   (tenant_id,customer_id,visit_at,order_id,amount,payment_method)
   values
   (b.tenant_id,visit_customer,visit_time,b.source_id,visit_amount,
    case when b.paid>0 then 'settled' else null end)
   returning id into v_id;
 else
   update public.crm_restaurant_visits
   set customer_id=visit_customer, visit_at=visit_time, amount=visit_amount,
       payment_method=case when b.paid>0 then coalesce(payment_method,'settled') else payment_method end
   where id=v_id;
 end if;
 update public.crm_customers c
 set total_restaurant_revenue=coalesce((select sum(rv.amount) from public.crm_restaurant_visits rv where rv.tenant_id=b.tenant_id and rv.customer_id=visit_customer),0),
     total_restaurant_visits=coalesce((select count(*) from public.crm_restaurant_visits rv where rv.tenant_id=b.tenant_id and rv.customer_id=visit_customer),0),
     updated_at=now()
 where c.id=visit_customer and c.tenant_id=b.tenant_id;
 return v_id;
end
$function$;

revoke execute on function public.anaira_sync_restaurant_visit_from_bill(uuid) from anon;
grant execute on function public.anaira_sync_restaurant_visit_from_bill(uuid) to authenticated;

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
 return jsonb_build_object('ok',true,'bill_id',b.id,'restaurant_visit_id',v);
end
$function$;

revoke execute on function public.anaira_close_crm_bill(uuid) from anon;
grant execute on function public.anaira_close_crm_bill(uuid) to authenticated;
