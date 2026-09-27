-- Anaira Plugin Control Center activation metadata
-- Adds audit fields used by Super Admin property-level plugin activation.
alter table public.restaurant_plugins
  add column if not exists activated_by uuid references auth.users(id) on delete set null,
  add column if not exists activated_at timestamptz,
  add column if not exists disabled_at timestamptz;

create index if not exists restaurant_plugins_activated_at_idx
  on public.restaurant_plugins(activated_at);

create index if not exists restaurant_plugins_enabled_idx
  on public.restaurant_plugins(restaurant_id, enabled);
