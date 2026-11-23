# OTA Dual Connection Routes — Release 2026-11-23

## Implemented
- Property OTA screen now offers two explicit routes: `anaira_managed` (Anaira Super Admin central provider account) and `property_managed` (property's own OTA account/authorization).
- Existing listing ID, OTA account email, current management method and owner consent are still required.
- API validates and persists the selected route.
- Property's submitted listing table displays the selected route.
- Super Admin existing-listing review queue displays the selected route.
- Additive migration adds `connection_mode` to existing link requests; old rows default to `property_managed`.
- Documentation explains both workflows, security boundaries and go-live requirements.

## Verification
- JavaScript syntax: 740/740 PASS
- Relative imports: PASS
- Dual-route static test: 10 checks PASS
- Existing listing request tests: 12 PASS
- Reservation normalization: 16 PASS
- Inbox lifecycle static: 14 PASS
- Replay safety static: 10 PASS
- Accommodation scope: 7 PASS
- Provider transport mock guard: 3 PASS

## Not claimed
- The migration has not been applied to live Supabase in this release.
- Route A does not magically grant OTA API access. Super Admin must have the relevant approved provider account/API credentials and attach the property through the provider's permitted workflow.
- Route B requires provider-side owner authorization/partner access. No OTA password is collected.
- No live provider certification or production sync is claimed.
