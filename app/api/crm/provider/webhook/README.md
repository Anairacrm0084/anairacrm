# CRM Provider Webhooks
POST `/api/crm/provider/webhook/{provider}` with `x-anaira-webhook-signature` = HMAC-SHA256(body, `CRM_WEBHOOK_SECRET` or provider-specific secret). Resolve tenant with `x-anaira-tenant-id` or an enabled `crm_provider_configs.sender_identity` matching `x-anaira-provider-identity`.
