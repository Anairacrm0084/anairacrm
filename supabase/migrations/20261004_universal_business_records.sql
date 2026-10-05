BEGIN;
CREATE TABLE IF NOT EXISTS public.anaira_business_records (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), business_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
 business_type text NOT NULL REFERENCES public.anaira_business_types(code), module_key text NOT NULL, title text NOT NULL,
 data jsonb NOT NULL DEFAULT '{}'::jsonb, status text NOT NULL DEFAULT 'active', sort_order integer NOT NULL DEFAULT 0,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.anaira_business_settings (
 business_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
 business_type text NOT NULL REFERENCES public.anaira_business_types(code), setting_key text NOT NULL, value jsonb NOT NULL DEFAULT '{}'::jsonb,
 updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(business_id,setting_key)
);
ALTER TABLE public.anaira_business_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anaira_business_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "business records tenant read" ON public.anaira_business_records;
CREATE POLICY "business records tenant read" ON public.anaira_business_records FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_records.business_id AND m.status='active'));
DROP POLICY IF EXISTS "business records tenant insert" ON public.anaira_business_records;
CREATE POLICY "business records tenant insert" ON public.anaira_business_records FOR INSERT TO authenticated WITH CHECK (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_records.business_id AND m.status='active'));
DROP POLICY IF EXISTS "business records tenant update" ON public.anaira_business_records;
CREATE POLICY "business records tenant update" ON public.anaira_business_records FOR UPDATE TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_records.business_id AND m.status='active')) WITH CHECK (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_records.business_id AND m.status='active'));
DROP POLICY IF EXISTS "business records tenant delete" ON public.anaira_business_records;
CREATE POLICY "business records tenant delete" ON public.anaira_business_records FOR DELETE TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_records.business_id AND m.status='active'));
DROP POLICY IF EXISTS "business settings tenant read" ON public.anaira_business_settings;
CREATE POLICY "business settings tenant read" ON public.anaira_business_settings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_settings.business_id AND m.status='active'));
DROP POLICY IF EXISTS "business settings tenant write" ON public.anaira_business_settings;
CREATE POLICY "business settings tenant write" ON public.anaira_business_settings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_settings.business_id AND m.status='active')) WITH CHECK (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_settings.business_id AND m.status='active'));
CREATE INDEX IF NOT EXISTS idx_business_records_tenant_module ON public.anaira_business_records(business_id,module_key,created_at DESC);
COMMIT;