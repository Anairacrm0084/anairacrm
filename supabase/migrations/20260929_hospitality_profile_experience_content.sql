-- Property-owned public experience content for all hospitality types.
alter table public.restaurants add column if not exists nearby_destinations jsonb not null default '[]'::jsonb;
alter table public.restaurants add column if not exists nearby_activities jsonb not null default '[]'::jsonb;
alter table public.restaurants add column if not exists hospitality_highlights jsonb not null default '[]'::jsonb;
