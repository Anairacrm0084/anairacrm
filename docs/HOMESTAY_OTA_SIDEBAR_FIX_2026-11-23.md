# Homestay OTA Sidebar and Property Profile Fix — 2026-11-23

## Plugin to enable

Enable the tenant-scoped `channel-manager` plugin (display name: **Channel / OTA Manager**) for the property. This controls the `/channel-manager` route and the new hospitality-specific sidebar entry. The homestay's own workspace remains controlled by `homestay-management`.

## Sidebar changes

- Added **Channel / OTA Manager** under the Homestay/Hotel/Camp/Guest House/Cottage Revenue & Distribution group, gated by `channel-manager`.
- Preserved **Edit <Property Type> Property Profile** under the property's management group.
- Expanded tenant-admin role aliases for property/homestay/camp/guest-house/cottage owners and managers so property settings are not hidden for these admin profiles.

## Notes

- No Supabase migration is required; this is a sidebar/role recognition source change.
- Enabling the plugin makes the module visible; it does not create OTA credentials or certify a live provider connection.
- The `homestay-management` plugin remains the Homestay PMS/profile plugin. Do not substitute it for `channel-manager` when enabling OTA access.
