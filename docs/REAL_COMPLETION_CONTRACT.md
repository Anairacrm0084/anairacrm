# ANAIRA REAL COMPLETION CONTRACT

This baseline must never mark a feature as Live/Connected/Production-ready merely because a UI record exists.

Every workflow must pass five gates:
1. DEFINED — contract/schema exists.
2. IMPLEMENTED — server transaction/RPC/adapter exists.
3. WIRED — UI/API calls the implementation.
4. TESTED — success, failure, duplicate, permission and tenant-isolation paths tested.
5. PRODUCTION-READY — provider secrets, monitoring, retries, audit and operational recovery are configured.

Provider integrations are intentionally stateful:
`not_configured -> credentials_saved -> validating -> verified -> connected -> error/disabled`.

No payment can become `paid` from a browser action. Only a verified provider callback/server transaction can do so.

No OTA connection can become connected without credential/API validation.
No AI insight is generated from placeholder data. Without a model/runtime it must say `Model not configured`.
No dashboard KPI is hardcoded as a live measurement.
No marketplace order may contain items from multiple restaurants.
Existing Anaira POS remains the canonical restaurant operational engine; this platform integrates with it rather than cloning it.
