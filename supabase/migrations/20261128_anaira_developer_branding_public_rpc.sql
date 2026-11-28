create or replace function public.anaira_get_developer_branding()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $function$
  select jsonb_build_object(
    'developer_logo_url',
    coalesce(
      (
        select nullif(value->>'value','')
        from public.anaira_platform_settings
        where key = 'anaira_developer_brand_logo_url'
      ),
      ''
    )
  );
$function$;

revoke all on function public.anaira_get_developer_branding() from public;
grant execute on function public.anaira_get_developer_branding() to anon, authenticated, service_role;
