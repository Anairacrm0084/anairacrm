# ANAIRA SEO — MASTER A-TO-Z LOCK
Date: 2026-09-25
Baseline: Phase 24 SEO source + Master A-to-Z audit

## Lock rule
No SEO feature is considered complete merely because a menu item or setting exists. A feature is complete only when its data model, tenant security, API/runtime behavior, UI/control surface, provider gating, audit/history and E2E verification are accounted for.

## A-to-Z completion matrix

### 1. Site / Project Foundation
- [x] Website onboarding
- [x] Tenant-scoped SEO sites
- [x] DNS TXT verification
- [x] Verification status/history foundation
- [x] Domain/subdomain/subfolder crawl-mode data model
- [x] Include/exclude path controls
- [x] User-agent/device controls
- [x] Crawl budget/delay controls
- [x] Staging/noindex flag
- [x] Archive flag
- [ ] HTML/meta-tag verification adapters — schema/control-plane ready; provider adapter remains deployment-specific

### 2. Technical SEO Crawler
- [x] HTTP status capture
- [x] 4xx/5xx issue detection
- [x] Redirect response/chain capture
- [x] Title checks
- [x] Meta description checks
- [x] H1 checks
- [x] Canonical checks
- [x] Noindex/indexability checks
- [x] ALT checks
- [x] Open Graph checks
- [x] Hreflang presence
- [x] JSON-LD validity
- [x] Language declaration
- [x] Viewport
- [x] Thin-content signal
- [x] Text/HTML ratio signal
- [x] Duplicate internal-link signal
- [x] Image dimension/lazy-load signals
- [x] Mixed-content signal
- [x] Security-header capture
- [x] Response time/page size
- [x] Crawl depth
- [x] Internal link graph storage
- [x] Content hash/history foundation
- [x] Crawl configuration persisted
- [x] Crawl comparison fields
- [ ] Full 140+/170+ discrete market issue parity — must not be represented as complete until every individual rule is independently implemented and E2E tested

### 3. Indexability / Sitemap / Robots
- [x] Sitemap URL management
- [x] GSC sitemap submission
- [x] Sitemap submission history
- [x] Robots editor
- [x] Robots versioning
- [x] Robots publish-state storage
- [x] Multi-site data model
- [x] Respect-robots runtime setting
- [ ] External customer-site deployment adapter — requires site/hosting connector

### 4. Issues / Pages Workflow
- [x] Issue severity
- [x] Issue categories
- [x] Affected URL
- [x] Issue fingerprint
- [x] Assignable issue field
- [x] Ignore/snooze field
- [x] Resolve timestamp
- [x] Last-seen/first-seen
- [x] Issue filtering API
- [x] Page inspector API
- [x] Page technical fields
- [x] Page crawl depth
- [x] Page link counts
- [x] Page score
- [x] Audit history
- [ ] Full ticket/task connector

### 5. Keywords
- [x] Seed research
- [x] Provider-gated live metrics
- [x] Search volume
- [x] Competition
- [x] Difficulty field
- [x] CPC
- [x] Trend storage
- [x] Intent classification
- [x] Intent confidence
- [x] Cluster/parent topic
- [x] Keyword-to-page target field
- [x] Group/tag field
- [x] Keyword country/device/search engine fields
- [x] Bulk storage model
- [x] Competitor keyword gap storage
- [ ] Full autocomplete/question/related-keyword provider adapter
- [ ] Full keyword cannibalization algorithm

### 6. Rankings / SERP
- [x] Live SERP provider
- [x] Position history
- [x] Target URL
- [x] SERP feature capture
- [x] Search engine field
- [x] Country field
- [x] City field in rank history schema
- [x] Device field
- [x] SERP snapshot storage
- [x] Competitor gap storage
- [ ] Full local-grid provider implementation
- [ ] Full SOV/visibility historical engine

### 7. Backlinks
- [x] Backlink data model
- [x] Referring-domain data model
- [x] New/lost history fields
- [x] Anchor/dofollow/sponsored/UGC fields
- [x] Authority/risk fields
- [x] Historical graph storage
- [x] Provider health/gating
- [x] Provider API endpoint
- [ ] Full provider ingestion/pagination and competitor link-intersect E2E

### 8. Local SEO / GBP
- [x] Location data model
- [x] Location metrics data model
- [x] Local keyword/grid data model
- [x] GBP provider readiness
- [x] Local ranking storage
- [x] Location dashboard surface
- [ ] Full Google Business Profile OAuth/location discovery/performance ingestion E2E
- [ ] Citation management provider adapter

### 9. GSC / GA4
- [x] GSC OAuth foundation
- [x] GSC Search Analytics foundation
- [x] GSC property selection
- [x] URL inspection foundation
- [x] Sitemap submission
- [x] GA4 OAuth foundation
- [x] GA4 report foundation
- [x] Property selection
- [x] Tenant-safe site linkage
- [ ] Full dashboard drilldowns/comparison/CTR opportunity/cannibalization UI E2E
- [ ] Full GA4 landing-page/conversion/organic attribution UI E2E

### 10. Content / AI
- [x] AI content generation
- [x] Approval workflow
- [x] Publishing gate
- [x] WordPress/webhook provider gating
- [x] Content versions table
- [x] Internal-link rules
- [x] AI internal-link suggestions
- [x] Schema generation
- [x] Schema approval
- [x] Schema publishing
- [ ] Full SERP content brief/editor/refresh/calendar/rollback E2E
- [ ] External Google rich-result validator integration

### 11. Competitor Intelligence
- [x] Competitor entity
- [x] Live SERP collection
- [x] Keyword gap table
- [x] Opportunity score field
- [x] Competitor history foundation
- [ ] Full content gap
- [ ] Full backlink gap/link intersect
- [ ] Full competitor visibility/SOV dashboard

### 12. AI / GEO Visibility
- [x] Prompt data model
- [x] Prompt execution
- [x] AI answer storage
- [x] Brand mention detection
- [x] Competitor mention storage
- [x] Citation storage
- [x] Sentiment/confidence fields
- [x] Visibility score field
- [x] Provider gating
- [ ] Multi-model provider adapters
- [ ] Longitudinal GEO benchmark and accuracy verification

### 13. Automation
- [x] Per-site job registry
- [x] Crawl job
- [x] GSC sync job
- [x] GA4 sync job
- [x] Rank sync job
- [x] PageSpeed job
- [x] Competitor sync job
- [x] Enable/disable
- [x] Interval
- [x] Next run
- [x] Run history
- [x] Run Now control
- [x] Retry/backoff
- [x] Provider prerequisites
- [x] Failure recording
- [ ] Full visual workflow builder with arbitrary trigger/action graph

### 14. Reports / Agency
- [x] Report configuration table
- [x] Cadence
- [x] Timezone
- [x] Recipients
- [x] Section selection
- [x] Branding fields
- [x] Run history
- [x] White-label data model
- [ ] Email delivery provider E2E
- [ ] Full PDF/CSV export renderer E2E
- [ ] Full multi-site portfolio dashboard
- [ ] Client read-only sharing E2E

### 15. Settings
- [x] SEO settings schema
- [x] Runtime settings API
- [x] Crawl max pages binding
- [x] Respect robots binding
- [x] Browser rendering binding
- [x] Sitemap/robots binding
- [x] Settings permission route mapping
- [x] Tenant-safe mutation path
- [ ] Every individual future setting must be added to this matrix before being marked complete

### 16. Super Admin / Business Admin
- [x] Super Admin SEO route
- [x] Super Admin SEO KPIs on /admin
- [x] SEO site count
- [x] Verified count
- [x] Open issue count
- [x] Automation failure count
- [x] Business Admin SEO entry point
- [x] Settings permission mapping
- [ ] Full per-tenant SEO drilldown/control plane
- [ ] Full provider credential health management UI

### 17. Security / Tenant Isolation
- [x] RLS on SEO tables
- [x] Tenant-oriented policies
- [x] Server-derived user identity for new mutations
- [x] Cron authentication
- [x] Provider secrets remain server-side
- [x] OAuth state signing
- [x] Provider token encryption helper
- [ ] Final security advisor review of all legacy SECURITY DEFINER functions

### 18. E2E Completion Gate
- [x] Source-level route coverage
- [x] Node syntax checks for modified JS routes/engine
- [x] Live migration applied
- [x] Live RLS audit verified
- [ ] Full npm install/build in clean environment
- [ ] Live provider credential E2E for every configured provider
- [ ] Real customer-site deployment E2E for sitemap/robots/redirects

## LOCK STATUS
The product/control-plane A-to-Z scope is now captured in this file and carried forward as the mandatory SEO checklist. Items explicitly marked [ ] are not to be silently treated as complete. Provider-gated items become complete only after the relevant credentials and live E2E verification succeed.
