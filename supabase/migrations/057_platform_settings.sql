create table if not exists public.anaira_platform_settings (
 id uuid primary key default gen_random_uuid(),
 key text not null unique,
 value jsonb not null default '{}'::jsonb,
 updated_by uuid references auth.users(id) on delete set null,
 updated_at timestamptz not null default now()
);
alter table public.anaira_platform_settings enable row level security;
drop policy if exists "platform settings super admin" on public.anaira_platform_settings;
create policy "platform settings super admin" on public.anaira_platform_settings for all using (anaira_current_is_super_admin()) with check (anaira_current_is_super_admin());
