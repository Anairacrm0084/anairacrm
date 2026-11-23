# OTA Duplicate React Key Fix — 2026-11-23

## Issue
The OTA Manager combines active HMS room/rate records with camp-specific unit/rate records. A shared UUID can appear in both sources, which can produce duplicate React keys in the room/rate `<option>` lists and mapping UI.

## Fix
Added `uniqueById()` to keep the first canonical row for each non-empty record ID before setting `roomTypes` and `ratePlans` state. This keeps React keys and controlled select values deterministic and avoids rendering duplicate records for the same UUID. No random keys are used; no database rows are changed or deleted.

## Validation
Run `node tests/ota/duplicate-react-key-guard.mjs` from the project root.
