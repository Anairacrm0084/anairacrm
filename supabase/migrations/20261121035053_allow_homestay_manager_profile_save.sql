-- Permit an authenticated property manager to maintain HMS settings for their own property.
-- This is tenant-scoped to profiles.restaurant_id and does not grant cross-property access.
CREATE OR REPLACE FUNCTION public.anaira_can_manage_hms_settings(p_restaurant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
  SELECT
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = (SELECT auth.uid())
        AND p.restaurant_id = p_restaurant_id
        AND p.role = 'manager'
        AND COALESCE(p.is_super_admin, false) = false
    );
$function$;

REVOKE ALL ON FUNCTION public.anaira_can_manage_hms_settings(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.anaira_can_manage_hms_settings(uuid) TO authenticated, service_role;

DROP POLICY IF EXISTS hms_settings_manager_insert ON public.hms_settings;
CREATE POLICY hms_settings_manager_insert
ON public.hms_settings
FOR INSERT
TO authenticated
WITH CHECK (public.anaira_can_manage_hms_settings(restaurant_id));

DROP POLICY IF EXISTS hms_settings_manager_update ON public.hms_settings;
CREATE POLICY hms_settings_manager_update
ON public.hms_settings
FOR UPDATE
TO authenticated
USING (public.anaira_can_manage_hms_settings(restaurant_id))
WITH CHECK (public.anaira_can_manage_hms_settings(restaurant_id));
