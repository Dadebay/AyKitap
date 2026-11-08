# iOS LLDB / OneSignal framework warning

## Diagnosis

- The iOS build completed successfully.
- `OneSignalCore ... maps to more than one section` and
  `libobjc.A.dylib is being read from process memory` are LLDB symbol/shared
  cache warnings, not OneSignal push runtime failures.
- Local dependency resolution is consistent: `onesignal_flutter 5.6.8` uses
  `OneSignalXCFramework 5.5.6`.

## Action

- Moved only Aýkitap's Xcode DerivedData and the LLDB SymbolCache to the
  recoverable backup directory:
  `/private/tmp/aykitap-xcode-debug-cache-backup-20260825`
- Xcode will recreate clean caches on the next debug run.
- No project build setting or OneSignal source was changed to hide the warning.
- No build was run.
