# Reader vertical swipe verification — 2026-11-10

## Change

- In `scroll` (Down/Prokrutka) mode, the Flutter pointer listener now handles vertical page turns on Android as well as iOS. Android WebView could cancel the iframe touch stream during a vertical drag, leaving that mode unable to advance despite horizontal gestures still doing so.
- The JavaScript scroll-mode swipe callback no longer sends a second page turn. The Flutter listener ignores a flick while text is selected and resets its gesture state on pointer cancellation.
- The earlier JavaScript changes also release selection polling timers when a section detaches or a new book loads, and refuse concurrent animated turns.

## Device evidence

- Physical Samsung SM A346E, Android, `flutter run --profile`, real EPUB “Восьмой свидетель”. Before the vertical fix, 40 upward swipes left the same page on screen, while one horizontal swipe advanced it. This revealed that the first vertical memory sample had not exercised page turns.
- After the fix, one upward swipe changed the text. A further 40 upward swipes advanced from chapter 1 at 5% to chapter 2 at 8%, without a freeze or crash. At the end, `dumpsys meminfo` showed 654,153 KB total PSS, 337,054 KB graphics, one WebView. The sample is one device/book, not proof for all users.
- The earlier 40 horizontal swipes also completed without a freeze; Dart/Flutter timeline showed no UI frames over 8.3 ms and one raster frame over 8.3 ms in the last batch. WebView renderer frames are outside that Flutter timeline.
- Real EPUB graphics memory remains high. An opaque WebView and explicit Flutter image-cache clearing did not materially reduce it, so both experiments were reverted. This native EGL/GL retention needs separate device/engine investigation.

## Verification

- `flutter build apk --profile` succeeded; final APK installed on the device.
- Launched that final APK and confirmed one upward swipe advanced the reopened EPUB to different text in chapter 2.
- `flutter analyze packages/sakura_epub/lib/src/epub_viewer.dart lib/modules/reader/views/reader_view_epub_viewer.dart` passed.
- `node --test packages/sakura_epub/test/epub_view_js_test.cjs` passed.
- Focused purchase-mode, streak, avatar-cache and shelf tests passed (24 tests). `git diff --check` passed.
- Server-side streak day attribution was left out at the user's request because the backend is unavailable.
