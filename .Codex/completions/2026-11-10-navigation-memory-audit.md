# Navigation memory and frame audit

## Scope

Static review of the Flutter app's main navigation, Home, Library, Search,
image handling, and reader allocation paths. The supplied DevTools screenshot
shows debug-mode frame times and jank, not a heap/RAM measurement.

## Findings and changes

- Library `ShelfGrid` eagerly built every row and cover inside a
  `SingleChildScrollView`. Replaced it with `ShelfGridSliver` and
  `CustomScrollView` in API, downloaded, and own-book shelves. Rows outside
  the viewport are now recycled.
- `StaggerFadeIn` kept every animated Search result alive during long
  pagination. Added an opt-out and disabled keep-alive on Search cards and
  shelf rows. Their entrance may replay when a recycled item scrolls back.
- Main navigation mounted all five tabs immediately. It now mounts each tab
  on first visit; visited tabs still retain their state.
- Home's banner auto-advance timer continued while the Home tab was hidden.
  It now follows the parent `TickerMode` visibility.
- Local profile avatars decoded a new base64 byte array on each rebuild and
  could decode a full-resolution photo for a small circle. The bytes now stay
  stable across rebuilds, clear when the photo changes, and use a bounded
  display-sized decode width.

## Remaining risk and measurement

- All visited main tabs still remain mounted, so a long session can retain
  their data and controllers. A bounded tab cache would save more memory but
  needs explicit scroll/query-state restoration and fetch policy.
- CBZ extraction reads the entire ZIP into memory in a background isolate.
  Large books may still cause a process-level memory spike; streaming
  extraction is a separate reader change.
- Compare before/after on representative devices with `flutter run --profile`
  and DevTools Memory plus Performance while repeatedly switching Library and
  Home. The screenshot alone cannot establish a RAM leak or quantify savings.

## Verification

- Focused widget tests for lazy shelf construction and stable avatar image
  provider passed.
- Existing Library sync, motion, and Search grid tests passed.
- Analyzer passed on all touched files. Whole-project analyzer still reports
  18 pre-existing issues in other files and bundled package code.

No session file was created.
