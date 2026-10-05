BEGIN;

-- Existing businesses historically used profiles.restaurant_id as the tenant link.
-- The universal business layer uses anaira_business_memberships, so backfill the
-- membership rows for existing profile-linked users before enforcing universal RLS.
INSERT INTO public.anaira_business_memberships
  (user_id, business_id, role, status, is_owner)
SELECT
  p.id,
  p.restaurant_id,
  COALESCE(NULLIF(p.role, ''), 'staff'),
  'active',
  (p.role IN ('owner','admin') OR COALESCE(p.is_super_admin,false))
FROM public.profiles p
WHERE p.restaurant_id IS NOT NULL
ON CONFLICT (user_id, business_id)
DO UPDATE SET
  status = 'active',
  role = EXCLUDED.role,
  is_owner = (public.anaira_business_memberships.is_owner OR EXCLUDED.is_owner),
  updated_at = now();

-- One access predicate for the universal business layer. It supports both the
-- new membership model and the legacy profiles.restaurant_id model.
CREATE OR REPLACE FUNCTION public.anaira_current_business_access(target_business_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    target_business_id IS NOT NULL
    AND (
      public.anaira_current_is_super_admin()
      OR EXISTS (
        SELECT 1
        FROM public.anaira_business_memberships m
        WHERE m.user_id = auth.uid()
          AND m.business_id = target_business_id
          AND m.status = 'active'
      )
      OR EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.restaurant_id = target_business_id
          AND COALESCE(p.status, 'active') = 'active'
      )
    );
$$;

-- Landing pages: this is the error shown in the Salon Setup screenshot.
DROP POLICY IF EXISTS "tenant landing insert" ON public.anaira_business_landing_pages;
CREATE POLICY "tenant landing insert" ON public.anaira_business_landing_pages
FOR INSERT TO authenticated
WITH CHECK (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "tenant landing update" ON public.anaira_business_landing_pages;
CREATE POLICY "tenant landing update" ON public.anaira_business_landing_pages
FOR UPDATE TO authenticated
USING (public.anaira_current_business_access(business_id))
WITH CHECK (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "tenant landing delete" ON public.anaira_business_landing_pages;
CREATE POLICY "tenant landing delete" ON public.anaira_business_landing_pages
FOR DELETE TO authenticated
USING (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "public published landing read" ON public.anaira_business_landing_pages;
CREATE POLICY "public published landing read" ON public.anaira_business_landing_pages
FOR SELECT TO anon, authenticated
USING (
  published = true
  OR public.anaira_current_business_access(business_id)
);

-- Universal media.
DROP POLICY IF EXISTS "business media tenant read" ON public.anaira_business_media;
CREATE POLICY "business media tenant read" ON public.anaira_business_media
FOR SELECT TO authenticated
USING (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business media tenant write" ON public.anaira_business_media;
CREATE POLICY "business media tenant write" ON public.anaira_business_media
FOR ALL TO authenticated
USING (public.anaira_current_business_access(business_id))
WITH CHECK (public.anaira_current_business_access(business_id));

-- Universal records/settings/workspaces used by the setup engines.
DROP POLICY IF EXISTS "business records tenant read" ON public.anaira_business_records;
CREATE POLICY "business records tenant read" ON public.anaira_business_records
FOR SELECT TO authenticated
USING (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business records tenant insert" ON public.anaira_business_records;
CREATE POLICY "business records tenant insert" ON public.anaira_business_records
FOR INSERT TO authenticated
WITH CHECK (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business records tenant update" ON public.anaira_business_records;
CREATE POLICY "business records tenant update" ON public.anaira_business_records
FOR UPDATE TO authenticated
USING (public.anaira_current_business_access(business_id))
WITH CHECK (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business records tenant delete" ON public.anaira_business_records;
CREATE POLICY "business records tenant delete" ON public.anaira_business_records
FOR DELETE TO authenticated
USING (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business settings tenant read" ON public.anaira_business_settings;
CREATE POLICY "business settings tenant read" ON public.anaira_business_settings
FOR SELECT TO authenticated
USING (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business settings tenant write" ON public.anaira_business_settings;
CREATE POLICY "business settings tenant write" ON public.anaira_business_settings
FOR ALL TO authenticated
USING (public.anaira_current_business_access(business_id))
WITH CHECK (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business workspace tenant read" ON public.anaira_business_workspaces;
CREATE POLICY "business workspace tenant read" ON public.anaira_business_workspaces
FOR SELECT TO authenticated
USING (public.anaira_current_business_access(business_id));

DROP POLICY IF EXISTS "business workspace tenant write" ON public.anaira_business_workspaces;
CREATE POLICY "business workspace tenant write" ON public.anaira_business_workspaces
FOR ALL TO authenticated
USING (public.anaira_current_business_access(business_id))
WITH CHECK (public.anaira_current_business_access(business_id));

COMMIT;
