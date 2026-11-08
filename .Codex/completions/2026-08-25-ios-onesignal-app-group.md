# iOS OneSignal App Group entitlement fix

## Diagnosis

- APNs token, OneSignal ID and push subscription ID are created successfully.
- OneSignal was probing its default App Group and iOS rejected it because the
  app is entitled to Aýkitap's existing widget group instead.
- The initial nil OneSignal ID warning occurs before asynchronous user creation
  finishes; the later ID/subscription observer output confirms recovery.

## Fix

- Added `OneSignal_app_groups_key` to `ios/Runner/Info.plist`.
- Pointed it to the already-entitled shared container:
  `group.com.aykitap.aykitap`.
- Kept the existing Runner and WidgetKit entitlements unchanged.

## Verification

- All three plist/entitlements files pass `plutil -lint`.
- The configured OneSignal group exactly matches the Runner entitlement.
- `git diff --check` passes for the changed plist.
- No iOS build was run.
