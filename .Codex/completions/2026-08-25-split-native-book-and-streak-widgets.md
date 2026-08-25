# Split native book and streak widgets

## Completed

- Split the combined widget into two independent Android and iOS picker items:
  `Continue Reading` and `Reading Streak`.
- Added the real Gilroy font to the Android widget resources and the iOS
  WidgetKit extension resources.
- Redesigned Continue Reading around the cached real book cover, title,
  current/total page, progress bar, and direct reader link.
- Redesigned Reading Streak to match the profile card: glowing flame, current
  streak, best streak, today's page count, and seven profile-style day circles.
- Added a Streak deep link so tapping the streak widget opens StreakScreen.
- Stored `best_streak` in the shared native widget state and refresh both widget
  kinds after book or streak changes.
- Raised the generated iOS widget target to the app's iOS 15.6 minimum so its
  SwiftUI styling APIs match the parent app.

## Verification

- Android layouts, provider XML, styles, manifest, iOS plist, and Xcode project
  files pass their structural parsers.
- Gilroy Android resource is byte-identical to the existing app font.
- Targeted changed files pass `git diff --check`.
- Per user request, no Flutter build, APK build, Xcode build, or installation
  was run.

