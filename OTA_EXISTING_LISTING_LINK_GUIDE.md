# Connect an Existing OTA Listing to Anaira

## Property Admin steps
1. Sign in to the correct Anaira hotel / camp / homestay / guest-house / cottage account.
2. Open **OTA & Channel Manager** from the hospitality sidebar.
3. Under **Connect an existing OTA listing**, select the OTA (Booking.com, Airbnb, Agoda, Expedia, MakeMyTrip, Goibibo, Trip.com or Hostelworld).
4. Open that OTA's existing extranet and copy the existing property/listing ID. Do not create a duplicate listing.
5. Enter the email used for that OTA account and select whether it is managed directly or through SiteMinder, STAAH or another channel manager.
6. Confirm owner/admin authorization and submit.
7. The listing appears in **Existing listings submitted** with `authorization_requested` status.

## What happens next
- Anaira records the property, provider, existing listing ID, account email, current channel manager and owner authorization.
- Anaira does not collect the OTA website password.
- A request is not a live connection. The provider / approved channel manager must authorize Anaira connectivity and the required OAuth/API contract and credentials must be configured by Anaira Super Admin.
- After approved authorization is available, room/rate codes must be mapped, future reservations reconciled, and test inventory/reservation sync completed before auto-sync is enabled.

## Safety
Never paste OTA passwords, OTPs, recovery codes or personal login cookies into Anaira support, screenshots or the old generic API credentials form. Do not enable auto-sync until room/rate mapping and existing bookings have been reconciled.

## Current release limitation
This release implements the authenticated existing-listing request form and its tenant-scoped database record. Provider-specific OAuth authorization/callbacks and Super Admin request-review UI are not included in this source-only step. It must not display a listing as connected until the provider authorization and API verification actually succeed.

## Super Admin review
- Open **Super Admin → Universal Integrations → Existing OTA Listing Requests**.
- Review the property, OTA listing ID, account email and current channel manager.
- Move the request to `Awaiting provider approval`, `Ready for official authorization`, `Needs information` or `Rejected`.
- Do not mark it connected manually. The connected state is reserved for a successful provider-specific OAuth/API authorization and verification.
