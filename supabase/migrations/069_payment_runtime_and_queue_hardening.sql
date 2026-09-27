-- ANAIRA 069: payment runtime + queue hardening
-- Provider credentials remain server-side. This migration never marks a provider connected.
alter table public.anaira_notification_queue add column if not exists payload jsonb not null default '{}'::jsonb;
alter table public.anaira_notification_queue add column if not exists updated_at timestamptz not null default now();

create table if not exists public.anaira_payment_refunds(
 id uuid primary key default gen_random_uuid(),
 payment_intent_id uuid not null references public.anaira_payment_intents(id) on delete cascade,
 amount numeric(14,2) not null,
 status text not null default 'requested',
 provider_refund_id text,
 reason text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.anaira_payment_attempts(
 id uuid primary key default gen_random_uuid(),
 payment_intent_id uuid not null references public.anaira_payment_intents(id) on delete cascade,
 provider text not null,
 provider_order_id text,
 provider_payment_id text,
 status text not null default 'created',
 error_code text,
 error_message text,
 raw_response jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists anaira_payment_refunds_intent_idx on public.anaira_payment_refunds(payment_intent_id,created_at desc);
create index if not exists anaira_payment_attempts_intent_idx on public.anaira_payment_attempts(payment_intent_id,created_at desc);
alter table public.anaira_payment_refunds enable row level security;
alter table public.anaira_payment_attempts enable row level security;
drop policy if exists anaira_payment_refunds_tenant on public.anaira_payment_refunds;
create policy anaira_payment_refunds_tenant on public.anaira_payment_refunds for all to authenticated using (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id()))) with check (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id())));
drop policy if exists anaira_payment_attempts_tenant on public.anaira_payment_attempts;
create policy anaira_payment_attempts_tenant on public.anaira_payment_attempts for all to authenticated using (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id()))) with check (exists(select 1 from public.anaira_payment_intents p where p.id=payment_intent_id and (public.anaira_current_is_super_admin() or p.restaurant_id=public.anaira_current_restaurant_id())));

create or replace function public.anaira_request_payment_refund(p_payment_intent_id uuid,p_amount numeric default null,p_reason text default null)
returns jsonb language plpgsql security invoker as $$
declare p public.anaira_payment_intents; already numeric; total_refunded numeric;
begin
 select * into p from public.anaira_payment_intents where id=p_payment_intent_id for update;
 if not found then raise exception 'Payment intent not found'; end if;
 if p.status not in ('paid','partially_refunded') then raise exception 'Only paid payments can be refunded'; end if;
 select coalesce(sum(amount),0) into total_refunded from public.anaira_payment_refunds where payment_intent_id=p.id and status in ('requested','processing','processed');
 already:=total_refunded; if coalesce(p_amount,p.amount-already)<=0 then raise exception 'Refund amount must be positive'; end if;
 if coalesce(p_amount,p.amount-already)>p.amount-already then raise exception 'Refund exceeds remaining payment'; end if;
 insert into public.anaira_payment_refunds(payment_intent_id,amount,reason) values(p.id,coalesce(p_amount,p.amount-already),p_reason) returning amount into p_amount;
 return jsonb_build_object('refund_requested',true,'payment_intent_id',p.id,'amount',p_amount,'remaining',p.amount-already-p_amount);
end $$;

create or replace function public.anaira_claim_notification_batch(p_limit integer default 25)
returns setof public.anaira_notification_queue language plpgsql security invoker as $$
begin
 return query update public.anaira_notification_queue q set status='processing',attempts=attempts+1,updated_at=now()
 where q.id in (select id from public.anaira_notification_queue where status='queued' and scheduled_at<=now() order by scheduled_at for update skip locked limit greatest(1,least(p_limit,100))) returning q.*;
end $$;
