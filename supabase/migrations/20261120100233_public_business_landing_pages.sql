-- Make every business landing page public by default, without requiring visitor login.
-- Draft privacy is still respected when an owner explicitly unpublishes a page.
BEGIN;

ALTER TABLE public.anaira_business_landing_pages
  ALTER COLUMN published SET DEFAULT true;

-- Ensure every existing business has a landing-page row and publish the existing
-- business landing pages. This is the requested one-time rollout for all business types.
INSERT INTO public.anaira_business_landing_pages
  (business_id, business_type, slug, headline, subheadline, theme, sections, published)
SELECT
  r.id,
  COALESCE(NULLIF(r.business_type, ''), 'general'),
  trim(both '-' from regexp_replace(
    lower(COALESCE(NULLIF(trim(r.name), ''), NULLIF(r.business_type, ''), r.id::text)),
    '[^a-z0-9]+', '-', 'g'
  )) || '-' || left(r.id::text, 8),
  COALESCE(NULLIF(trim(r.name), ''), 'Welcome'),
  COALESCE(NULLIF(trim(r.description), ''), 'Welcome to our business.'),
  '{}'::jsonb,
  '[{"key":"hero","enabled":true},{"key":"about","enabled":true},{"key":"catalog","enabled":true},{"key":"team","enabled":true},{"key":"offers","enabled":true},{"key":"gallery","enabled":true},{"key":"testimonials","enabled":true},{"key":"contact","enabled":true}]'::jsonb,
  true
FROM public.restaurants r
ON CONFLICT (business_id) DO UPDATE
SET published = true,
    updated_at = now();

-- Ensure anonymous visitors can read only published landing pages.
ALTER TABLE public.anaira_business_landing_pages ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.anaira_business_landing_pages TO anon, authenticated;
DROP POLICY IF EXISTS "anaira_public_published_landing_read" ON public.anaira_business_landing_pages;
CREATE POLICY "anaira_public_published_landing_read"
  ON public.anaira_business_landing_pages
  FOR SELECT TO anon
  USING (published = true);

-- Public page content is readable only for businesses with a published landing page.
ALTER TABLE public.anaira_business_records ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.anaira_business_records TO anon, authenticated;
DROP POLICY IF EXISTS "anaira_public_published_records_read" ON public.anaira_business_records;
CREATE POLICY "anaira_public_published_records_read"
  ON public.anaira_business_records
  FOR SELECT TO anon
  USING (EXISTS (
    SELECT 1 FROM public.anaira_business_landing_pages lp
    WHERE lp.business_id = anaira_business_records.business_id
      AND lp.published = true
      AND anaira_business_records.module_key IN ('primary','team','products','services','treatments','packages','portfolio','collections','projects','programs','memberships','spaces','venues','destinations','courses','testimonials','offers','case_studies','faq')
  ));

ALTER TABLE public.anaira_business_media ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.anaira_business_media TO anon, authenticated;
DROP POLICY IF EXISTS "anaira_public_published_media_read" ON public.anaira_business_media;
CREATE POLICY "anaira_public_published_media_read"
  ON public.anaira_business_media
  FOR SELECT TO anon
  USING (active = true AND EXISTS (
    SELECT 1 FROM public.anaira_business_landing_pages lp
    WHERE lp.business_id = ana_business_media.business_id
      AND lp.published = true
  ));

ALTER TABLE public.anaira_business_offers ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.anaira_business_offers TO anon, authenticated;
DROP POLICY IF EXISTS "anaira_public_published_offers_read" ON public.anaira_business_offers;
CREATE POLICY "anaira_public_published_offers_read"
  ON public.anaira_business_offers
  FOR SELECT TO anon
  USING (active = true AND EXISTS (
    SELECT 1 FROM public.anaira_business_landing_pages lp
    WHERE lp.business_id = ana_business_offers.business_id
      AND lp.published = true
  ));

COMMIT;
