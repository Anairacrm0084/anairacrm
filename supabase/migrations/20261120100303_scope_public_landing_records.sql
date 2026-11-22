-- Public storefront content only: do not expose operational/CRM records to anon.
BEGIN;
DROP POLICY IF EXISTS "anaira_public_published_records_read" ON public.anaira_business_records;
CREATE POLICY "anaira_public_published_records_read"
  ON public.anaira_business_records
  FOR SELECT TO anon
  USING (
    module_key IN (
      'primary','team','products','services','treatments','packages','portfolio',
      'collections','projects','programs','memberships','spaces','venues',
      'destinations','courses','testimonials','offers','case_studies','faq'
    )
    AND EXISTS (
      SELECT 1 FROM public.anaira_business_landing_pages lp
      WHERE lp.business_id = anaira_business_records.business_id
        AND lp.published = true
    )
  );
COMMIT;
