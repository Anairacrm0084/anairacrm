# Phase 21 — Plugin Independence Baseline

The 40-plugin catalog is the canonical product surface. Every plugin has an explicit runtime manifest, settings schema, permissions namespace, data owner, dependency declaration and event boundary.

No plugin owns another plugin’s operational tables. Cross-plugin dependencies are read/event/API dependencies only. Anaira POS remains an operational bridge and is not reimplemented in CRM.

Settings are tenant-scoped. Custom settings are stored separately under `custom_settings` and are auditable. Secrets must remain in server-side integration infrastructure; the plugin settings UI never treats arbitrary values as provider secrets.

Empty database results are rendered as “No live records yet”; no demo rows are injected.
