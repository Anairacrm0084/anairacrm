# Anaira SEO — Phase 29 A-to-Z Completion Matrix

Date: 2026-09-25

## Implemented in this pass
- Crawl parser/runtime field mismatch fixed (`scripts`, `scriptSrc`, `externalScripts` compatibility).
- Crawl link snapshots isolated per audit and duplicate-safe.
- Orphan classification changed to graph-wide inbound-link detection, not sitemap-only.
- Page detail link lookup fixed to resolve by page URL.
- Invalid `target_url` page PATCH field removed.
- GSC daily dimension/date persistence fixed; historical rows retain provider date.
- GSC URL inspection results persisted into `crm_seo_gsc_inspections`.
- GBP location/insights path migrated to current Business Profile v1 / Business Performance v1 endpoints.
- Backlink fingerprints + incremental/lost-link persistence added; provider collection can paginate/search-after up to configured cap.
- Report builder audit query fixed; PDF/CSV/HTML render paths added; report config update/delete added.
- Full SEO runtime settings UI added for all feature flags.
- SEO permissions registered and bound to admin/manager roles.
- Content reject actor now comes from authenticated session, not request body.
- Redirect duplicate index removed.
- 198 JavaScript files syntax-checked successfully in final source tree.

## Still externally gated (not falsely marked PASS)
- Real provider E2E requires customer credentials: GSC, GA4, DataForSEO, SerpAPI, Google Business Profile, Browserless, PageSpeed, OpenAI, publishing/mail provider.
- Customer-domain deployment E2E requires an actual customer website/CMS and credentials.
- Full production build remains unverified because dependency installation timed out in this environment.
- 140+/170+ market-equivalent technical issue count is not claimed merely from a numeric rule count; each check must be validated against real crawl fixtures.
