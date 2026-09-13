# Reader: scroll no longer toggles the chrome, and progress survives leaving the app

Two separate bugs reported together, both in the reader.

## 1. Every scroll flipped the top/bottom bars (EPUB)

**Symptom.** Scrolling up from the bottom of a page made the reader chrome
appear; scrolling again hid it. There was no way to stay in focus mode — the
bars flipped on essentially every gesture.

**Cause.** `_onTouchUp` decided tap-vs-scroll by comparing the touch-down and
touch-up coordinates the WebView reports. `epubView.js` computes those as
`iframeRect.top + touch.clientY` (`getNormalizedTouchCoordinates`), and every
page-transition mode animates the viewer with a `translateY(...)`
(`epubView.js` ~line 2161). So while a page is moving, the frame those
coordinates are measured in moves *with the finger*, by roughly the same
distance. A 300px scroll therefore reported a start and an end a couple of
pixels apart and passed the `moved <= 0.03` tap test.

Two smaller contributors on the same path: `epubView.js` attaches touch
listeners to the iframe document, the parent document *and* the window, each
debounced only against itself, so one physical touch is reported more than
once — and a duplicate touch-down re-anchored the gesture mid-scroll, while a
duplicate touch-up could toggle a second time.

**Fix.** New `lib/modules/reader/utils/reader_tap_gate.dart` — `ReaderTapGate`
decides this from three signals instead of one, with the unreliable one last:

1. Flutter's own pointer stream, via the `Listener` already wrapping the
   viewer in `reader_view_body.dart` (it was only `debugPrint`ing). Its
   coordinates are in the screen's frame, so the moving iframe can't distort
   them. Optional, since platform views don't forward pointers identically
   everywhere.
2. `ReaderProvider.lastRelocationAt` — if the book actually moved around the
   gesture, it was a scroll or a page turn. No tap ever moves the book.
3. The WebView delta, as a last-resort fallback.

Plus strict down/up pairing, so duplicate reports can't toggle twice or
re-anchor a gesture in flight, with a staleness bound so a dropped touch-up
can't wedge the gate shut.

## 2. The last pages read were lost on leaving the app (EPUB, PDF, CBZ)

**Symptom.** Reading, then swiping the app away, reopened the book at an
older page rather than where reading stopped.

**Cause.** All three readers persist position on a 2-second debounce
(`onRelocated` / `_onPageChanged`). Nothing flushed it when the app was
backgrounded: `_handleAppLifecycleState` only flushed the streak residual. A
suspended process can be killed before that pending timer ever fires, so
everything read in the last two seconds of a session — which is exactly how a
reading session normally ends — never reached disk.

**Fix.** On `paused`/`detached`/`hidden`, all three readers now cancel the
debounce and write immediately: `ReaderProviderLifecycle._flushPendingProgressSave`
(EPUB), and the equivalent two lines in `pdf_reader_screen_lifecycle.dart` and
`cbz_reader_screen_lifecycle.dart`.

## Changed files

- **new** `lib/modules/reader/utils/reader_tap_gate.dart`
- `lib/modules/reader/views/reader_view.dart` (holds the gate)
- `lib/modules/reader/views/reader_view_body.dart` (`Listener` now feeds the gate)
- `lib/modules/reader/views/reader_view_epub_viewer.dart` (uses the gate)
- `lib/modules/reader/provider/reader_provider.dart` + `_callbacks.dart` +
  `_persistence.dart` (`lastRelocationAt`)
- `lib/modules/reader/provider/reader_provider_lifecycle.dart`
- `lib/modules/reader/views/pdf_reader_screen_lifecycle.dart`
- `lib/modules/reader/views/cbz_reader_screen_lifecycle.dart`
- **new** `test/modules/reader/reader_tap_gate_test.dart` (14 tests)
- `test/modules/reader/reader_provider_lifecycle_test.dart` (+2 tests)

`packages/sakura_epub` was left untouched — the fix sits entirely on the
Flutter side, so the vendored JS coordinate math is not disturbed.

## Verification

- `flutter test test/modules/reader/` — 55/55 pass.
- Both new persistence tests were confirmed to **fail** with the flush removed,
  so they genuinely pin the bug rather than passing incidentally.
- `flutter analyze lib/modules/reader test/modules/reader` — no new issues
  (22 pre-existing style infos remain).
- `flutter test` — 267 pass, 2 fail. Both failures are in
  `test/modules/profile/settings_screen_revenue_cat_test.dart` and were
  confirmed to fail identically with these reader changes stashed — they belong
  to the in-progress RevenueCat/IAP work already uncommitted in the tree.

## Still worth checking on a device

The chrome should now only toggle on a deliberate still tap, in every
transition mode (Prokrutka included), and a book should reopen exactly where
it was left after force-quitting the app from each of EPUB, PDF and CBZ.
