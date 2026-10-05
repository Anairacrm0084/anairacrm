-- ANAIRA HOTEL GUEST CRM LOYALTY REVERSAL
-- Immutable adjustment/reversal workflow for loyalty transactions.
create or replace function public.anaira_reverse_loyalty_transaction(p_transaction_id uuid,p_reason text default null)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare t public.crm_loyalty_transactions; a public.crm_loyalty_accounts; r uuid;
begin
 select * into t from public.crm_loyalty_transactions where id=p_transaction_id for update;
 if t.id is null then raise exception 'LOYALTY_TRANSACTION_NOT_FOUND'; end if;
 if t.reversed_at is not null then raise exception 'LOYALTY_TRANSACTION_ALREADY_REVERSED'; end if;
 select * into a from public.crm_loyalty_accounts where id=t.loyalty_account_id for update;
 if a.id is null then raise exception 'LOYALTY_ACCOUNT_NOT_FOUND'; end if;
 insert into public.crm_loyalty_transactions(loyalty_account_id,points,transaction_type,reference_type,reference_id,notes)
 values(a.id,-t.points,'reversal','loyalty_transaction',t.id::text,coalesce(p_reason,'Reversal')) returning id into r;
 update public.crm_loyalty_transactions set reversed_at=now(),reversed_transaction_id=r where id=t.id;
 update public.crm_loyalty_accounts set points_balance=points_balance-t.points,updated_at=now() where id=a.id;
 return jsonb_build_object('original_transaction_id',t.id,'reversal_transaction_id',r,'status','reversed');
end $$;
revoke all on function public.anaira_reverse_loyalty_transaction(uuid,text) from public;
grant execute on function public.anaira_reverse_loyalty_transaction(uuid,text) to authenticated;
