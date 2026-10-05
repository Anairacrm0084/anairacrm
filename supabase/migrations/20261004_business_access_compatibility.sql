-- Anaira Universal Business Access Compatibility / RLS Closure
-- Fixes legacy businesses that have profiles.restaurant_id but no universal membership row.
BEGIN;

INSERT INTO public.anaira_business_memberships
  (user_id, business_id, role, profile_key, status, is_owner)
SELECT p.id, p.restaurant_id,
       CASE WHEN p.is_super_admin THEN 'super_admin' ELSE 'owner' END,
       'legacy_profile', 'active', true
FROM public.profiles p
WHERE p.restaurant_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.anaira_business_memberships m
    WHERE m.user_id=p.id AND m.business_id=p.restaurant_id
  );

DROP POLICY IF EXISTS "tenant landing insert" ON public.anaira_business_landing_pages;
CREATE POLICY "tenant landing insert" ON public.anaira_business_landing_pages
FOR INSERT TO authenticated
WITH CHECK (
  public.anaira_current_is_super_admin()
  OR public.anaira_tenant_access(business_id)
  OR public.anaira_current_restaurant_id()=business_id
);

DROP POLICY IF EXISTS "tenant landing update" ON public.anaira_business_landing_pages;
CREATE POLICY "tenant landing update" ON public.anaira_business_landing_pages
FOR UPDATE TO authenticated
USING (
  public.anaira_current_is_super_admin()
  OR public.anaira_tenant_access(business_id)
  OR public.anaira_current_restaurant_id()=business_id
)
WITH CHECK (
  public.anaira_current_is_super_admin()
  OR public.anaira_tenant_access(business_id)
  OR public.anaira_current_restaurant_id()=business_id
);

DROP POLICY IF EXISTS "public published landing read" ON public.anaira_business_landing_pages;
CREATE POLICY "public published landing read" ON public.anaira_business_landing_pages
FOR SELECT TO anon, authenticated
USING (
  published=true
  OR public.anaira_current_is_super_admin()
  OR public.anaira_tenant_access(business_id)
  OR public.anaira_current_restaurant_id()=business_id
);

DROP POLICY IF EXISTS "business media tenant write" ON public.anaira_business_media;
CREATE POLICY "business media tenant write" ON public.anaira_business_media
FOR ALL TO authenticated
USING (
  public.anaira_current_is_super_admin()
  OR public.anaira_tenant_access(business_id)
  OR public.anaira_current_restaurant_id()=business_id
)
WITH CHECK (
  public.anaira_current_is_super_admin()
  OR public.anaira_tenant_access(business_id)
  OR public.anaira_current_restaurant_id()=business_id
);

DROP POLICY IF EXISTS "business media tenant read" ON public.anaira_business_media;
CREATE POLICY "business media tenant read" ON public.anaira_business_media
FOR SELECT TO authenticated
USING (
  public.anaira_current_is_super_admin()
  OR public.anaira_tenant_access(business_id)
  OR public.anaira_current_restaurant_id()=business_id
);

COMMIT;
