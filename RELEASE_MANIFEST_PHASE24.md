# Anaira CRM — Phase 24 SEO Real Command Center

Date: 2026-09-25

This release upgrades SEO from a mostly functional surface into a real site-onboarding and automation workflow.

## Added
- Domain creation wizard
- DNS TXT domain verification
- Per-site verification state
- Per-site sitemap/robots URLs
- GSC OAuth with authenticated start flow
- GSC property discovery and selection
- GSC Search Analytics sync
- GSC URL Inspection
- GSC sitemap submission
- GA4 OAuth, property discovery and selection
- Live keyword provider enforcement
- Live SERP rank provider enforcement
- PageSpeed Insights integration and persistence
- SEO score history
- Per-site automation jobs and runs
- Scheduled SEO worker
- Real crawl engine shared by manual and scheduled execution
- AI content approval/publishing pipeline
- AI/rule-based internal linking
- Schema approval/publishing pipeline
- Competitor SERP collection
- Production environment guide

## Truth policy
No fake keyword volume, rank, PageSpeed, Google, GA4 or AI results are generated when providers are unavailable.

Third-party website mutation is only claimed after the configured connector accepts the publish request.
