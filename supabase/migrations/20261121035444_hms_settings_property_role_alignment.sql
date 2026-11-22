-- Align HMS property profile writes with the role resolution used by the app.
-- Access remains tenant-scoped: non-super-admins can only write their own property.
CREATE OR REPLACE FUNCTION public.anaira_can_manage_hms_settings(p_restaurant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
  SELECT auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = (SELECT auth.uid())
        AND COALESCE(p.status, 'active') = 'active'
        AND (
          COALESCE(p.is_super_admin, false) = true
          OR p.role = 'super_admin'
          OR (
            p.restaurant_id = p_restaurant_id
            AND p.role IN ('manager', 'admin', 'business_admin')
          )
        )
    );
$function$;

CREATE OR REPLACE FUNCTION public.anaira_current_is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = (SELECT auth.uid())
      AND COALESCE(p.status, 'active') = 'active'
      AND (COALESCE(p.is_super_admin, false) = true OR p.role = 'super_admin')
  );
$function$;

REVOKE ALL ON FUNCTION public.anaira_can_manage_hms_settings(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.anaira_can_manage_hms_settings(uuid) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.anaira_current_is_super_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.anaira_current_is_super_admin() TO authenticated, service_role;
