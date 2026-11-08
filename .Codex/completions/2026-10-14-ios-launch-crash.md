# iOS launch crash — 1.1.7 (18)

## Evidence and cause

- All five supplied App Review crash reports have the same SIGABRT / UserDefaults exception backtrace.
- Matched Runner UUID `CD5B803D-7A60-385E-9719-8C405BDA576D` to the dSYM in the 2026-10-14 13.36 Xcode archive.
- Symbolicated Runner offsets 2836164 and 2858068 with `atos`: `specialized HomeWidgetPlugin.handle(_:result:)` and `@objc HomeWidgetPlugin.handle(_:result:)`. The immediately preceding frame is `-[NSUserDefaults setObject:forKey:]`.
- Startup sync passes nullable last-read-book fields to home_widget 0.9.3. Its Swift handler passes method-channel NSNull values to UserDefaults instead of removing the keys, causing a native exception outside Dart's try/catch.

## Changes

- Normalize absent book ID, title, author, page count, and cover path to the native widgets' existing empty-state values (`-1`, placeholder title, empty string, `0`, empty string).
- Keep real book metadata, cover caching, streak updates, and the startup sequence unchanged. No backend or dependency changes.
- Add five method-channel regression tests for first launch, clearing stale state, missing metadata/cover, and preserving existing metadata/cover.
- Increment app build to 1.1.7+19 in pubspec and all Runner Xcode configurations.

## Verification

- Before the fix: four new regression tests failed on null widget values; the existing-book case passed.
- After the fix: all 17 widget-service and app-bootstrap tests passed.
- Focused Dart analysis: no issues. `git diff --check` and plist/project syntax checks passed.
- Signed release build succeeded; built app Info.plist reports version 1.1.7, build 19.
- iPad (A16), iPadOS 27.0.1: release app installed and process survived initial launch and relaunch. Shared widget defaults contained the expected non-null empty-book values. Full foreground UI verification was not completed; user requested switching testing to the wired iPhone.
- Wired iPhone XS Max, iOS 18.7.7: release build 19 installed. After the user completed Face ID, the home page and book lists loaded successfully. Then terminated/relaunched the app with devicectl; the new Runner process (PID 95089) remained alive and another screenshot confirmed the fully loaded home page. Initial launch and cold relaunch passed. App left running on the iPhone.

## Handoff

Archive and upload build 19 for App Review. No App Store upload or review response was sent by this task. The exact review-device model (iPad Air M3) was not available. Existing unrelated working-tree changes were preserved.
