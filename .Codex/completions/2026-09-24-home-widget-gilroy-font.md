# Home widget Gilroy font and vertical layout

## Problem

The Android home-screen widgets declared `@font/gilroy_regular` in XML, but
`RemoteViews` are inflated inside the launcher process. Some OEM launchers
failed to resolve the app-owned font resource and silently rendered widget
text with the system font.

## Change

- Added a shared Android widget font helper that loads the packaged Gilroy
  typeface and carries it with every dynamic text value through a
  `TypefaceSpan` on Android 9 and newer.
- Routed all reading-widget and streak-widget text updates through the helper,
  including placeholder, progress, stat label, and weekday values.
- Kept the XML font family as the fallback for older Android versions.
- Preserved the existing iOS WidgetKit setup, whose extension bundle includes
  `Gilroy-Regular.ttf`, registers it in `UIAppFonts`, and uses its verified
  `Gilroy-Regular` PostScript name.
- Empty dynamic labels skip span creation to avoid invalid zero-length spans.
- Replaced the centred fixed-height content blocks with RemoteViews-safe
  weighted spacing. The streak header/week bands now sit at the top/bottom,
  and the reading widget keeps metadata at the top with progress/action at the
  bottom.
- Reduced real vertical edge padding from 10–11dp to 8dp while preserving the
  horizontal padding and compact minimum-height layouts.

## Verification

- Android `app:compileDebugKotlin` and `app:mergeDebugResources`: passed.
- Both changed widget layouts pass `xmllint` validation and Android resource
  packaging.
- Packaged debug resources contain `font/gilroy_regular.ttf`.
- Android and Flutter copies of Gilroy have identical SHA-256 hashes.
- iOS widget Info.plist is valid and the font PostScript name matches the
  SwiftUI `.custom` declaration.
- `git diff --check`: passed.
