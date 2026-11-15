# Reader, streak and subscription fixes — 2026-11-10

## Findings and changes

- EPUB content hooks created a new 2-second selection scan for every rendered section. Detached chapter frames could retain 200 ms pollers and their DOM. The reader now keeps one scan per book, prunes detached frames, and clears polling when another book loads.
- A second page command during a transition still called `rendition.next/prev`, despite the guard comment. Rapid commands now wait for the current turn instead of stacking EPUB requests.
- The bottom navigation disk repainted for selection animation even though its paint output never used the selected position. Removed that repaint trigger.
- Streak pings now report measured foreground seconds when a timer fires late. Pending reports are restored before adding new time, persisted in order before sending, and concurrent reports cannot submit the same seconds twice. The week ring and history labels use the server's `today.date` when available.
- Subscriptions now use the backend's account-specific `purchaseMode`: `store_iap` opens RevenueCat/App Store or Google Play; `wallet` opens the existing TMT flow, except when the iOS store-only override is enabled. Unknown Android billing mode shows a localized retry error instead of defaulting a foreign account to TMT. Logout clears the old account's cached purchase mode.

## Verification

- Android physical device `SM A346E`: pre-fix warmed navigation profile showed 1/355 UI frames and 3/355 raster frames above 8.3 ms in the sampled window; total process PSS after visiting several screens was about 485 MB, with about 182 MB graphics memory. This is a short sample, not a long-session leak measurement.
- Rebuilt and installed Android profile APK after the initial reader/nav fixes. The device subsequently locked; post-fix page-turn profiling could not be completed.
- `node --check` on `epubView.js` and `node packages/sakura_epub/test/epub_view_js_test.cjs` passed.
- Focused Flutter tests covering purchase mode, streak persistence/concurrency, reader progress, motion, shelf laziness and avatar cache passed; touched-file analysis and `git diff --check` passed.
- Full `flutter test` encountered existing settings payment widget assertions (`ListTile` below `DecoratedBox`) and stalled in a gift-sheet test; interrupted after 1m37s. It is not a clean full-suite result.
- iOS profile launch on the wireless iPhone failed at Xcode destination resolution. An iOS simulator debug build compiled and opened to onboarding, but it had no signed-in account/book for reader profiling; RevenueCat requests were blocked in that simulator environment. No iOS performance or purchase sample.

## Remaining dependency

`POST /streaks/report` accepts seconds/pages/book ID but no reading timestamp or day. The server assigns the Ashgabat day. Backdating offline reading or choosing the user's local day requires a backend contract and implementation change, plus tests at the midnight boundary. Backend code is not in this workspace.
