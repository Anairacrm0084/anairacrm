-- Additive compatibility repair: older application queries sort these tables by created_at.
-- Existing business timestamps (delivery_orders.placed_at) remain unchanged.
alter table public.booking_addons
  add column if not exists created_at timestamptz not null default now();

alter table public.delivery_orders
  add column if not exists created_at timestamptz not null default now();

comment on column public.delivery_orders.created_at is
  'Record creation timestamp for API compatibility; placed_at remains the customer order placement timestamp.';
