### 1. Site / Domain Onboarding

- Domain add
- Multi-site support
- Domain verification
- DNS TXT verification
- HTML file verification
- Meta-tag verification
- Verification re-check
- Verification history
- Verified / Pending / Failed status
- Domain migration
- Domain change workflow
- Subdomain project
- Subfolder project
- Staging / noindex mode
- HTTPS canonical enforcement
- Archive / delete workflow
- Onboarding checklist

### 2. Crawl Configuration

- Crawl source: website
- Crawl source: sitemap
- Crawl source: robots.txt
- Custom sitemap URL
- File/import sitemap
- Include URL patterns
- Exclude URL patterns
- Query-parameter rules
- User-agent selection
- Desktop crawl
- Mobile crawl
- JS rendering toggle
- Browser rendering config
- Crawl max pages
- Crawl concurrency
- Crawl delay/throttle
- Crawl timeout
- Crawl depth
- Crawl budget
- Subdomain inclusion
- Crawl segments
- Crawl configuration history

### 3. Technical SEO Crawler

- HTTP status checks
- 2xx detection
- 3xx detection
- 4xx detection
- 5xx detection
- Broken links
- Redirect chains
- Redirect loops
- Redirect status correctness
- Canonical checks
- Canonical-to-redirect conflict
- Canonical-to-noindex conflict
- Canonical host/protocol normalization
- Title missing
- Title length
- Duplicate titles
- Meta description missing
- Meta description length
- Duplicate meta descriptions
- H1 missing
- Multiple H1
- Duplicate H1
- Thin content
- Near-duplicate content
- Content hash comparison
- Content-to-HTML ratio
- Word count
- Readability signals
- Noindex detection
- Nofollow detection
- Indexability matrix
- Robots directive analysis
- robots.txt conflicts
- Sitemap coverage
- Sitemap mismatch
- Orphan pages
- Crawl depth
- Internal links
- External links
- Broken external links
- Link depth
- Duplicate URLs
- Query parameter duplicates
- Soft-404 detection
- HTTPS check
- HTTP→HTTPS check
- Mixed content
- Security headers
- Mobile viewport
- Language declaration
- Hreflang presence
- Hreflang return-link validation
- Hreflang cluster validation
- JSON-LD parse
- Structured data coverage
- Structured data type validation
- Image ALT
- Image dimensions
- Image format
- Image compression opportunity
- Lazy-loading checks
- Script weight
- CSS weight
- HTML/page size
- Page response time
- Core Web Vitals
- PageSpeed integration
- AI crawler accessibility
- Specialist checks where applicable
- Rule registry/versioning
- Severity
- Category
- Evidence
- Recommendation
- Affected URL
- Rule fixture tests
- 140+/170+ class rule coverage

Original audit explicitly identified the existing crawler as materially narrower than mature tools and called for a versioned rule registry plus per-rule testing/evidence.

---

# 4. Crawl Comparison / Regression

- Previous audit selection
- Current vs previous comparison
- New issues
- Resolved issues
- Persistent issues
- Regressed issues
- Score delta
- New pages
- Removed pages
- Changed pages
- Issue history
- Regression dashboard
- Comparison export

---

# 5. Issue Management

- Issue list
- Severity filter
- Category filter
- Issue-code filter
- Status filter
- Affected-page count
- Issue detail
- Evidence viewer
- Recommendation
- Auto-fix indicator
- Assign user
- Ignore
- Snooze
- Resolve
- Bulk actions
- Issue history
- Recrawl verification
- Reopened issue handling
- Developer/task integration
- Ticket/task reference

The audit specifically calls out evidence, affected-page counts, assignment, ignore/snooze and verification after recrawl as required UI capabilities.

---

# 6. Pages

- Pages table
- Search
- Filters
- Sorting
- Pagination
- Page detail
- Technical score
- Content score
- Keyword score
- Total score
- HTTP status
- Canonical
- Robots
- H1/title/meta
- Internal links
- External links
- Orphan state
- Issue drilldown
- SERP preview
- Keyword mapping
- Page optimizer
- Page history
- Page diff
- Bulk metadata actions
- Export

---

# 7. Keyword Research

- Seed keyword
- Related keywords
- Keyword ideas
- Autocomplete
- Questions
- Search intent
- Intent confidence
- Keyword difficulty
- Search volume
- CPC
- Trend
- Seasonality
- Traffic potential
- Parent topic
- SERP overview
- SERP features
- Keyword clustering
- Cluster management
- Keyword groups
- Tags
- Bulk import
- Bulk export
- Keyword-to-page mapping
- Keyword history
- Keyword cannibalization
- Competitor keyword gap
- Opportunity score

The previous audit correctly notes that a provider competition index should not automatically be represented as a true keyword-difficulty score.

---

# 8. Rank Tracking

- Keyword tracking
- Country
- State/region where provider supports
- City
- ZIP/local location
- Search engine
- Desktop
- Mobile
- Local pack
- Grid tracking
- Tracking schedule
- Rank history
- Rank distribution
- Winners
- Losers
- SERP features
- Competitor overlay
- Visibility
- Share of voice
- Keyword groups
- Alerts
- Anomaly detection
- Location-level history
- Export

---

# 9. Competitor Intelligence

- Competitor add/edit/delete
- Competitor health
- Competitor domain overview
- Keyword gap
- Content gap
- Organic page gap
- SERP overlap
- Rank comparison
- Visibility comparison
- Share of voice
- Backlink gap
- Link intersect
- Competitor history
- Competitor alerts
- Competitor dashboard

---

# 10. Backlink Intelligence

- Backlink provider adapter
- Provider authentication
- Backlink discovery
- Backlink persistence
- Pagination
- Referring domains
- New backlinks
- Lost backlinks
- Anchor distribution
- Dofollow/nofollow
- Sponsored/UGC
- Source URL
- Target URL
- Authority/rank
- Spam/risk score
- Historical graph
- Competitor backlink gap
- Link intersect
- Deduplication
- Snapshot history
- Provider failure/retry
- Import/export

---

# 11. Local SEO / GBP

- Google OAuth
- Google Business Profile account discovery
- Location discovery
- Location manager
- Location verification status
- Business name
- Address
- Phone
- Website
- Category
- GBP metrics
- Daily metrics history
- Local keywords
- Local rankings
- Local pack
- Local grid
- Competitor local comparison
- NAP audit
- Citation manager
- Citation status
- Multi-location support
- Location-level dashboards
- Sync history
- Current Google API compatibility

The audit identifies GBP as only foundation-level and specifically requires OAuth, location discovery, ingestion, grid execution and citation management.

---

# 12. Google Search Console

- OAuth
- Property discovery
- Property connection
- Search Analytics
- Historical dates
- Query view
- Page view
- Country
- Device
- Search appearance
- Clicks
- Impressions
- CTR
- Position
- Date comparison
- CTR opportunities
- Quick wins
- Cannibalization
- Sitemap health
- URL inspection
- Inspection history
- Indexing workflow
- Error workflow
- Sync history
- Retry

---

# 13. GA4 SEO Analytics

- OAuth
- Property/measurement mapping
- Date range
- Date comparison
- Organic sessions
- Users
- Landing pages
- Channels
- Conversions
- Revenue where configured
- Organic vs non-organic
- Landing-page conversion
- SEO-attributed conversion
- SEO-attributed revenue
- Charts
- Trends
- Export

---

# 14. PageSpeed / Performance

- PageSpeed API
- Mobile score
- Desktop score
- Core Web Vitals
- LCP
- INP
- CLS
- Performance history
- Page-level records
- Opportunities
- Diagnostics
- Trend comparison

---

# 15. Content Intelligence / Optimizer

- Content brief
- Keyword target
- Target URL
- SERP competitor analysis
- Title recommendations
- Meta recommendations
- Outline
- Questions
- Entities
- Topic coverage
- NLP/topic recommendations
- Keyword coverage
- Readability
- Content score
- Optimization score
- Existing content analysis
- Duplicate/overlap detection
- Refresh workflow
- AI generation
- Human approval
- Editor
- Versions
- Diff
- Rollback
- Publish target
- Publish verification
- Content calendar

---

# 16. AI Content

- OpenAI provider
- Provider settings
- Content generation
- Meta generation
- Title generation
- Brief generation
- FAQ generation
- Schema content support
- Approval workflow
- Reject workflow
- Versioning
- AI run logs
- Token/cost telemetry
- Error/retry
- Publish verification
- Rollback

---

# 17. Internal Linking

- Crawl link graph
- Source page
- Target page
- Anchor text
- Link type
- Nofollow
- Inlink count
- Outlink count
- Orphan detection
- Opportunity graph
- Source filtering
- Target filtering
- Anchor recommendations
- Duplicate anchor warnings
- Placement suggestions
- Click-distance analysis
- Apply
- Rollback
- Change history
- Post-change validation

---

# 18. Schema Management

- Schema generation
- Schema template library
- Schema editor
- Page mapping
- Field-level validation
- Schema.org validation
- Google Rich Results validation
- Conflict detection
- Existing-schema comparison
- Version history
- Diff
- Approval
- Publish
- Publish verification
- Rollback

---

# 19. Redirect Manager

- Redirect list
- Create
- Edit
- Delete
- 301
- 302 / supported codes
- Source validation
- Target validation
- Redirect test
- Loop detection
- Chain detection
- Import
- Export
- History
- Rollback
- Customer-site deployment
- Deployment status
- Deployment error handling

---

# 20. Sitemap Manager

- Sitemap generation
- Sitemap editor
- Sitemap index
- URL sitemap
- Image sitemap
- Video sitemap
- News sitemap
- Exclusions
- Exclusion reasons
- Stale URL detection
- Crawl-vs-sitemap comparison
- Index-vs-sitemap comparison
- Validation
- Submission
- Submission history
- GSC status
- Customer-site publishing
- Deployment verification

---

# 21. Robots Manager

- Robots editor
- User-agent rules
- Allow
- Disallow
- Sitemap directive
- Bot-specific rules
- Standards-complete parser
- Rule tester
- Effective rule tester
- Version history
- Publish
- Rollback
- Customer-site deployment
- Deployment verification

---

# 22. AI / GEO Visibility

- Prompt library
- Prompt groups
- Locale
- Country/location
- Provider selection
- Google AI Overview
- Google AI Mode
- Other supported AI/search providers
- Answer capture
- Brand mention
- Competitor mention
- Citation extraction
- Source URLs
- Sentiment
- Accuracy
- Visibility score
- Share of voice
- Prompt history
- Model comparison
- Provider comparison
- Longitudinal trends
- Benchmarking
- GEO recommendations
- Run history
- Failure/retry

---

# 23. Automation

- Scheduled crawl
- GSC sync
- GA4 sync
- Rank sync
- PageSpeed sync
- Competitor sync
- Backlink sync
- GBP sync
- GEO runs
- Report generation
- Frequency editor
- Timezone
- Start/end window
- Retry policy
- Provider prerequisites
- Run Now
- Last run
- Next run
- Duration
- Logs
- Outputs
- Failure alerts
- Notification policy
- Workflow builder
- Trigger builder
- Action builder
- Conditions
- Branching
- Arbitrary trigger/action graph
- Workflow history

---

# 24. Reports

- Report configuration
- Report sections
- Live data rendering
- HTML report
- CSV report
- PDF report
- Branding
- Logo
- White-label
- Date range
- Comparison
- SEO health
- Technical issues
- Rankings
- GSC
- GA4
- Backlinks
- Local SEO
- GEO
- Content
- Competitors
- Report history
- Schedule
- Email delivery
- Delivery history
- Failure/retry
- Client read-only sharing
- Multi-site portfolio reporting

---

# 25. SEO Settings

### Crawl settings

- `crawl_max_pages`
- `respect_robots`
- `browser_rendering`
- crawl delay
- crawl mode
- device
- user agent
- include/exclude
- parameter policy

### Feature settings

- `sitemap_enabled`
- `robots_enabled`
- `gsc_enabled`
- `ga4_enabled`
- `rank_tracking_enabled`
- `ai_content_enabled`
- `internal_links_enabled`
- `schema_enabled`
- `redirects_enabled`
- `technical_issues`
- `keyword_research_enabled`
- `backlinks_enabled`
- `local_seo_enabled`
- `geo_visibility_enabled`
- `competitor_intelligence_enabled`
- `reports_enabled`

### Common controls

- Access
- Notifications
- Audit logging
- Retry
- Email
- WhatsApp
- SMS
- Provider prerequisites

**Har setting ko UI → DB → API → worker → runtime behavior tak trace karna hai.**

---

# 26. Provider Management

- DataForSEO
- SerpAPI
- Browserless
- Google Search Console
- Google Analytics
- Google Business Profile
- OpenAI
- Email provider
- PDF/report service if external
- WordPress/CMS
- Provider connection status
- Credential health
- Last successful call
- Last failure
- Latency
- Retry
- Rate-limit handling
- Usage/limits
- Secure secret storage

---

# 27. Super Admin SEO Control Center

- Total SEO sites
- Verified sites
- Pending sites
- Failed verification
- Average SEO health
- Critical issues
- Crawl failures
- GSC-connected sites
- GA4-connected sites
- GBP-connected sites
- Rank-tracking sites
- Backlink provider health
- GEO provider health
- Automation failures
- Last crawl
- Next crawl
- Worker status
- Provider health
- Tenant drilldown
- Configuration compliance
- SEO site portfolio
- Cross-tenant operational overview
- Audit logs

---

# 28. Business Admin SEO Control Center

- SEO dashboard
- Site portfolio
- Health summary
- Open issues
- Critical issues
- Crawl status
- Rankings
- GSC
- GA4
- Backlinks
- Local SEO
- GEO
- Content
- Reports
- Provider setup
- SEO settings
- Issue ownership
- Task queue
- Site-specific permissions

---

# 29. RBAC / Permissions

- `seo-system.view`
- `seo-system.manage`
- `seo-system.configure`
- Route-level enforcement
- API-level enforcement
- Mutation-level enforcement
- Settings permission
- Provider credential permission
- Report permission
- Site management permission
- Super Admin-only platform controls
- Business Admin tenant controls
- Server-derived actor identity
- No caller-controlled authorization
- No client-only security

The audit explicitly identifies the distinction between authentication and operation-specific authorization as a remaining concern.

---

# 30. Multi-Tenant Architecture

- Tenant isolation
- Site isolation
- Tenant-scoped APIs
- Tenant-scoped workers
- Tenant-scoped reports
- Tenant-scoped providers
- Multi-site selector
- Portfolio dashboard
- Cross-site comparison
- Agency/client workspace
- Client read-only access
- White-label branding
- Per-site deployment target
- No single-site `limit(1)` public architecture

---

# 31. Public Deployment

- Customer sitemap deployment
- Customer robots deployment
- Redirect deployment
- Metadata/content publishing
- Schema publishing
- WordPress publishing
- Deployment target configuration
- Deployment status
- Deployment logs
- Deployment rollback
- Verification after deployment
- Domain-specific serving architecture

---

# 32. Security

- RLS on all SEO tables
- Tenant policies
- Secure OAuth token storage
- Secret encryption/sealing
- No service-role in browser
- Server-side provider calls
- API authorization
- Settings authorization
- Actor identity from session
- Audit trail
- Retention policy
- Provider secret rotation
- Security advisor review
- SECURITY DEFINER review
- Function search_path hardening
- Leaked-password protection
- Sensitive-state policies

---

# 33. Performance / Scale

- Crawl batching
- Bulk DB writes
- Crawl queue
- Provider pagination
- Rate limiting
- Concurrency control
- Retry/backoff
- Dead-letter handling
- Large-site plan/limits
- 10k+ crawl strategy
- Indexed foreign keys
- Query performance
- Duplicate indexes removed
- Cache strategy
- Async provider calls
- Worker observability

---

# 34. Audit / History

- Audit history
- Page change history
- Issue history
- Redirect history
- Robots version history
- Schema history
- Content history
- Link change history
- Ranking history
- Backlink history
- GSC inspection history
- Report history
- Automation history
- Provider history
- Configuration change audit

---

# 35. Alerts / Notifications

- Critical SEO issue alert
- Crawl failure alert
- Ranking drop alert
- Ranking gain alert
- Traffic drop alert
- GSC issue alert
- GA4 anomaly alert
- Backlink lost alert
- GBP sync failure
- GEO visibility drop
- Automation failure
- Provider failure
- Report delivery failure
- Email notification
- WhatsApp notification
- SMS notification
- In-app notification

---

# 36. Export / Import

- Issues CSV
- Pages CSV
- Keywords CSV
- Rankings CSV
- Backlinks CSV
- Competitors CSV
- Redirects CSV
- Sitemap export
- Robots export
- Reports CSV
- Reports PDF
- Bulk keyword import
- Bulk competitor import
- Redirect import
- Validation on imports

---

# 37. Testing

- Unit tests
- Crawl fixture tests
- Technical rule tests
- Issue persistence tests
- Graph/orphan tests
- Keyword provider tests
- Rank provider tests
- Backlink provider tests
- GBP tests
- GSC tests
- GA4 tests
- Content tests
- Schema tests
- Redirect tests
- Sitemap tests
- Robots tests
- GEO tests
- Automation tests
- Report tests
- RBAC tests
- RLS tests
- Multi-tenant tests
- Deployment tests

---

# 38. Full E2E Certification

### E2E #1

- Create site
- Verify domain
- Configure crawl
- Crawl
- Persist pages
- Persist links
- Calculate inlinks
- Detect orphan
- Generate issues
- Resolve issue
- Recrawl
- Verify resolution
- Compare audits

### E2E #2

- Add keyword
- Discover keywords
- Cluster
- Map to page
- Track rank
- Store history
- Compare competitor
- Alert on change

### E2E #3

- Sync backlinks
- Persist backlinks
- Persist domains
- New/lost calculation
- Competitor backlink gap

### E2E #4

- GBP OAuth
- Discover locations
- Sync metrics
- Local keyword rank
- Local grid
- NAP/citation audit

### E2E #5

- GSC OAuth
- Historical sync
- Dashboard
- URL inspection
- Inspection history

### E2E #6

- GA4 OAuth
- Historical sync
- Landing pages
- Organic traffic
- Conversion analytics

### E2E #7

- Content brief
- AI content
- Optimize
- Approve
- Publish
- Verify
- Rollback

### E2E #8

- Schema generate
- Validate
- Approve
- Publish
- Verify
- Rollback

### E2E #9

- Redirect create
- Test
- Detect loop
- Publish
- Verify
- Rollback

### E2E #10

- Sitemap generate
- Validate
- Submit GSC
- Publish customer site
- Verify

### E2E #11

- Robots configure
- Test rule
- Publish
- Verify
- Rollback

### E2E #12

- GEO prompt
- AI Overview
- AI Mode
- Capture citations
- Competitor mentions
- Calculate visibility
- History
- Trend

### E2E #13

- Automation create
- Schedule
- Run
- Retry
- Log
- Alert
- Complete

### E2E #14

- Report configure
- Generate
- HTML
- CSV
- PDF
- Send email
- Schedule next run
- Delivery history

---

# 39. Build / Release Gate

- Clean `npm install`
- Lockfile valid
- TypeScript validation
- ESLint
- JS syntax
- Production build
- API route compilation
- DB migration verification
- Supabase security advisor
- Supabase performance advisor
- No duplicate indexes
- No broken imports
- No undefined DB columns
- No dead runtime tables
- No fake/demo provider responses
- No hardcoded KPI data
- Release manifest updated
- Master checklist updated

---

# 🔴 Certification Rule

**SEO ko `A-TO-Z COMPLETE` tabhi mark karna hai jab:**
`Data Model`
→ `Security/RLS`
→ `API/Runtime`
→ `UI`
→ `Provider`
→ `Persistence/History`
→ `Error/Retry`
→ `E2E`
→ `Production Build`
→ `Documentation`
**sab PASS ho.** Ye same completion rule forensic audit mein explicitly defined hai.