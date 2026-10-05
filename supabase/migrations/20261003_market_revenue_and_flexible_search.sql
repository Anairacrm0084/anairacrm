-- Anaira market closure: channel economics + flexible-date support metadata.
-- External OTA/GDS/metasearch certification remains environment-dependent.

create table if not exists public.crm_channel_economics (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  channel text not null,
  metric_date date not null,
  gross_booking_value numeric(14,2) not null default 0,
  ota_commission numeric(14,2) not null default 0,
  payment_fee numeric(14,2) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  refund_amount numeric(14,2) not null default 0,
  discount_amount numeric(14,2) not null default 0,
  net_revenue numeric(14,2) generated always as (gross_booking_value - ota_commission - payment_fee - tax_amount - refund_amount - discount_amount) stored,
  currency text not null default 'INR',
  source text,
  created_at timestamptz not null default now(),
  unique(tenant_id,channel,metric_date)
);

create index if not exists crm_channel_economics_tenant_date_idx on public.crm_channel_economics(tenant_id,metric_date);
alter table public.crm_channel_economics enable row level security;
drop policy if exists crm_channel_economics_tenant on public.crm_channel_economics;
create policy crm_channel_economics_tenant on public.crm_channel_economics
for all to authenticated
using (tenant_id = (select restaurant_id from public.profiles where id = auth.uid()))
with check (tenant_id = (select restaurant_id from public.profiles where id = auth.uid()));

create or replace view public.crm_channel_profitability with (security_invoker=true) as
select tenant_id, channel, metric_date, currency,
       gross_booking_value, ota_commission, payment_fee, tax_amount,
       refund_amount, discount_amount, net_revenue,
       case when gross_booking_value > 0 then round(net_revenue/gross_booking_value*100,2) else 0 end as net_margin_percent
from public.crm_channel_economics;
