-- Anaira Booking Engine canonical activation / distribution control
-- Idempotent: safe to apply after prior integration migrations.
update public.anaira_distribution_platforms
set active = true, updated_at = now()
where provider_code = 'anaira_booking_engine';

insert into public.anaira_platform_settings(key,value,updated_at)
values
 ('global_booking_engine_enabled', '{"value":true}'::jsonb, now()),
 ('marketplace_booking_enabled', '{"value":true}'::jsonb, now())
on conflict (key) do update
set value = excluded.value, updated_at = excluded.updated_at;
