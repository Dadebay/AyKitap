# Android widget data and inflation fix

## Completed

- Replaced the unsupported plain `View` in the Android `RemoteViews` layout
  with a supported horizontal `ProgressBar`. This was the cause of Samsung
  One UI showing `Couldn't add widget` both in the picker and home screen.
- Added real last-read book title, current page, total pages, reading progress,
  streak, and cached book-cover rendering to the Android widget.
- Downsamples book-cover bitmaps before sending them through `RemoteViews` to
  avoid Android binder-size failures.
- Connected native widget refreshes to book open, reader page changes, streak
  refreshes, and successful reading reports.
- Kept text/progress updates independent of cover downloads, so a failed image
  request cannot leave the widget empty.
- Removed the unused generated Glance receiver and its Compose/Glance Gradle
  configuration so Android exposes only the implemented Aýkitap widget.

## Verification

- Widget XML resources parse successfully with `xmllint`.
- Targeted changed files pass `git diff --check`.
- Per user request, no Flutter build, APK build, or device installation was run.

