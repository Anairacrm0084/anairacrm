# Anaira SEO — Phase 28 Completion Matrix
Date: 2026-09-25

## Implemented in this pass

- Crawl issue persistence now has a real `url`, page-id resolution, fingerprints, evidence and failure propagation.
- Crawl graph now aggregates inbound links and persists orphan state for sitemap-discovered pages.
- Crawl audit comparison records new/resolved/persistent issue fingerprints and score delta.
- Redirects now have source-path uniqueness, PATCH/update, loop checks, HTTP testing and history.
- Backlink endpoint now normalizes and persists provider backlink rows, referring domains and daily history.
- Keyword research route expanded to provider-backed ideas/related/suggestions/site discovery and intent enrichment.
- Rank tracking accepts country/device/search-engine/location and stores SERP snapshots.
- GBP/local workspace has OAuth, account discovery, location sync and insights ingestion foundations.
- AI/GEO can use Google AI Overview data through SerpAPI and optional OpenAI web-grounded analysis; citations are persisted.
- Report route can render HTML/CSV and create report runs from live data.
- Issues API now supports richer filters/grouping and audit history.
- Pages API now supports detail/history, metadata updates and CSV export.
- Competitor manager has list/delete/collect behavior.
- New SEO workflow tables exist for cannibalization, keyword clusters, GSC inspections, local citations, schema validation, content briefs/optimization, automation workflows and deployment targets.
- New SEO tables are RLS-enabled with tenant-aware policies.

## Still provider/E2E dependent

These are intentionally NOT marked certified until real credentials and external-site tests run:

1. DataForSEO production backlink/keyword account E2E.
2. Google Business Profile production OAuth/location/insights E2E.
3. SerpAPI production rank/local/AI Overview E2E.
4. Customer-site sitemap/robots/redirect/content deployment E2E.
5. Actual outbound report email/PDF delivery provider E2E.
6. WordPress/CMS publishing E2E.
7. Clean `npm install && npm run build` — install timed out in this environment.
8. Full automated E2E suite against a real tenant/site.

## Important product truth

The 140+/170+ market benchmark is a breadth benchmark, not a promise that every vendor's issue taxonomy is identical. Anaira's technical engine remains a versioned rule system and must be fixture-tested before being called market-equivalent.

## Certification rule

A module is only `[x]` after:
- schema exists
- tenant/RBAC path exists
- runtime works
- UI works
- provider works when applicable
- persistence/history works
- error/retry works
- E2E passes
- production build passes
- documentation is updated

Current release status: **Phase 28 hardening implemented; production certification remains blocked by provider credentials, customer-site E2E, full build and full E2E.**
