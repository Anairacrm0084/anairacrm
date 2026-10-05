-- Restaurant CRM full action runtime: property-aware loyalty metadata and indexes.
create or replace function public.anaira_sync_loyalty_property()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare p uuid; t uuid;
begin
  if TG_TABLE_NAME='crm_loyalty_accounts' then
    select c.property_id,c.tenant_id into p,t from public.crm_customers c where c.id=new.customer_id;
    new.property_id:=coalesce(new.property_id,p); new.tenant_id:=coalesce(new.tenant_id,t);
  elsif TG_TABLE_NAME='crm_loyalty_transactions' then
    select a.property_id,a.tenant_id into p,t from public.crm_loyalty_accounts a where a.id=new.loyalty_account_id;
    new.property_id:=coalesce(new.property_id,p); new.tenant_id:=coalesce(new.tenant_id,t);
  end if;
  return new;
end $$;
drop trigger if exists trg_crm_loyalty_accounts_property on public.crm_loyalty_accounts;
create trigger trg_crm_loyalty_accounts_property before insert or update on public.crm_loyalty_accounts for each row execute function public.anaira_sync_loyalty_property();
drop trigger if exists trg_crm_loyalty_transactions_property on public.crm_loyalty_transactions;
create trigger trg_crm_loyalty_transactions_property before insert or update on public.crm_loyalty_transactions for each row execute function public.anaira_sync_loyalty_property();
update public.crm_loyalty_accounts a set property_id=c.property_id,tenant_id=c.tenant_id from public.crm_customers c where c.id=a.customer_id and a.property_id is null and c.property_id is not null;
update public.crm_loyalty_transactions t set property_id=a.property_id,tenant_id=a.tenant_id from public.crm_loyalty_accounts a where a.id=t.loyalty_account_id and t.property_id is null and a.property_id is not null;
create index if not exists crm_loyalty_accounts_property_idx on public.crm_loyalty_accounts(tenant_id,property_id,customer_id);
create index if not exists crm_loyalty_transactions_property_idx on public.crm_loyalty_transactions(tenant_id,property_id,created_at desc);
