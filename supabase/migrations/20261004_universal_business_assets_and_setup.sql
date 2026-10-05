BEGIN;
CREATE TABLE IF NOT EXISTS public.anaira_business_media (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 business_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
 business_type text NOT NULL REFERENCES public.anaira_business_types(code),
 media_type text NOT NULL DEFAULT 'image',
 title text,
 url text NOT NULL,
 alt_text text,
 sort_order integer NOT NULL DEFAULT 0,
 active boolean NOT NULL DEFAULT true,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_anaira_business_media_tenant ON public.anaira_business_media(business_id,media_type,sort_order);
ALTER TABLE public.anaira_business_media ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "business media tenant read" ON public.anaira_business_media;
CREATE POLICY "business media tenant read" ON public.anaira_business_media FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_media.business_id AND m.status='active'));
DROP POLICY IF EXISTS "business media tenant write" ON public.anaira_business_media;
CREATE POLICY "business media tenant write" ON public.anaira_business_media FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_media.business_id AND m.status='active')) WITH CHECK (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=anaira_business_media.business_id AND m.status='active'));
INSERT INTO storage.buckets (id,name,public) VALUES ('anaira-business-assets','anaira-business-assets',true) ON CONFLICT (id) DO NOTHING;
DROP POLICY IF EXISTS "anaira business assets public read" ON storage.objects;
CREATE POLICY "anaira business assets public read" ON storage.objects FOR SELECT USING (bucket_id='anaira-business-assets');
DROP POLICY IF EXISTS "anaira business assets authenticated upload" ON storage.objects;
CREATE POLICY "anaira business assets authenticated upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id='anaira-business-assets');
DROP POLICY IF EXISTS "anaira business assets authenticated update" ON storage.objects;
CREATE POLICY "anaira business assets authenticated update" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id='anaira-business-assets') WITH CHECK (bucket_id='anaira-business-assets');
DROP POLICY IF EXISTS "anaira business assets authenticated delete" ON storage.objects;
CREATE POLICY "anaira business assets authenticated delete" ON storage.objects FOR DELETE TO authenticated USING (bucket_id='anaira-business-assets');
-- Public storefront reads are limited to records belonging to a published landing page.
DROP POLICY IF EXISTS "business records published storefront read" ON public.anaira_business_records;
CREATE POLICY "business records published storefront read" ON public.anaira_business_records FOR SELECT TO anon, authenticated USING (EXISTS (SELECT 1 FROM public.anaira_business_landing_pages lp WHERE lp.business_id=anaira_business_records.business_id AND lp.published=true));
DROP POLICY IF EXISTS "business media published storefront read" ON public.anaira_business_media;
CREATE POLICY "business media published storefront read" ON public.anaira_business_media FOR SELECT TO anon, authenticated USING (EXISTS (SELECT 1 FROM public.anaira_business_landing_pages lp WHERE lp.business_id=anaira_business_media.business_id AND lp.published=true));

COMMIT;
