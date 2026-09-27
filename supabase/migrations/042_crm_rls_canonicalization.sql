-- 042: canonical CRM tenant RLS for every crm_* table.
-- This supersedes the early scaffold policies that used authenticated using(true).
-- Direct tenant tables use tenant_id; relationship tables inherit tenant access from their parent CRM aggregate.
do $$
declare r record; expr text;
begin
  for r in select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE' and table_name like 'crm_%' loop
    execute format('drop policy if exists %I on public.%I', 'crm_tenant_access', r.table_name);
    if exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='tenant_id') then
      expr := format('anaira_can_access_tenant(tenant_id)');
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='customer_id') then
      expr := format('(exists (select 1 from public.crm_customers c where c.id=%I.customer_id and anaira_can_access_tenant(c.tenant_id)))', r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='campaign_id') then
      expr := format('(exists (select 1 from public.crm_campaigns c where c.id=%I.campaign_id and anaira_can_access_tenant(c.tenant_id)))', r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='corporate_account_id') then
      expr := format('(exists (select 1 from public.crm_corporate_accounts c where c.id=%I.corporate_account_id and anaira_can_access_tenant(c.tenant_id)))', r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='event_id') then
      expr := format('(exists (select 1 from public.crm_events e where e.id=%I.event_id and anaira_can_access_tenant(e.tenant_id)))', r.table_name);
    elsif exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.table_name and column_name='loyalty_account_id') then
      expr := format('(exists (select 1 from public.crm_loyalty_accounts a join public.crm_customers c on c.id=a.customer_id where a.id=%I.loyalty_account_id and anaira_can_access_tenant(c.tenant_id)))', r.table_name);
    else
      continue;
    end if;
    execute format('create policy %I on public.%I for all to authenticated using (%s) with check (%s)', 'crm_tenant_access', r.table_name, expr, expr);
  end loop;
end $$;
