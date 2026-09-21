# Reader settings: "Ýatyk okamak" (landscape reading)

**Request:** a button in the reader settings sheet so the reader can choose to read sideways.

## Why a setting at all
Landscape was *already allowed* while any reader is open. But a phone with the
system rotation lock switched on never leaves portrait however it is held, so
the reader had no way to ask. Flutter's preferred orientations outrank that
lock — so the setting works by **dropping portrait from the allowed set**, not
by adding landscape.

## Bug found while testing: the phone rocked between portrait and landscape
Reported as "1 yatay geçiyor 1 dikey oluyor, durmuyor yatayliğina".

`resolveAllowedOrientations` checked the window's **width class first**. But
turning a phone sideways widens the window past the compact breakpoint — so
the instant the phone obeyed, the rule saw a medium/expanded window, returned
"no preference", the device fell back to portrait, the window read compact
again, landscape was forced again. A loop the rule created itself, because its
answer depended on a width that its own answer produced.

Fix: the forced-landscape branch is decided **before** the width class, so the
answer is stable under the rotation it causes. A wide window is still
unrestricted whenever the reader has *not* asked for landscape.

## Where the button is
In **all three** readers' settings sheets — EPUB, PDF and CBZ. The setting is
app-wide and governs whichever book is open, so putting it only in the EPUB
sheet would hide it from anyone reading a PDF or a comic; they would have had
to open an EPUB to find a switch that controls the book already in front of
them.

Because the PDF and CBZ readers are plain screens with no `ReaderProvider`
above them, `ReaderLandscapeRow` owns its own state and reads/writes the
stored value directly — one switch, one stored value, no mirror in the
provider (the earlier `ReaderProvider.landscapeReading` mirror was removed for
exactly that reason).

## Where it lives
The preference (`reader_landscape`) is read and applied by
`AppOrientationPolicy`, the single place that calls
`SystemChrome.setPreferredOrientations`. All three readers (EPUB, PDF, CBZ)
already call `enableReaderLandscape()` on open, so all three honour it without
changing their screens.

- `lib/core/layout/app_orientation_policy.dart` — `setReaderActive(bool, {forcesLandscape})`; rule extracted as the pure `resolveAllowedOrientations(...)`.
- `lib/modules/reader/utils/reader_orientation.dart` — `readerLandscapePrefKey`, `setReaderLandscapeReading(bool)` (saves *and* turns the phone at once, since the switch is flipped from inside an open book).
- `lib/modules/reader/widgets/reader_landscape_row.dart` — new self-contained row; reuses the app's own `AppSwitch` pill.
- `reader_settings_sheet.dart` (under the page-transition row), `pdf_settings_sheet.dart`, `cbz_settings_sheet.dart` — the row added to each.
- `lib/core/localization/strings/reader_strings.dart` — `landscapeReadingTitle` (tk/ru/tr/en).

## Tests
- `test/core/layout/app_orientation_policy_test.dart` — 9 tests; the key ones assert portrait is *absent* when forced, and that the forced set survives the wide window rotating into landscape produces (the flip-flop regression).
- `test/modules/reader/reader_landscape_setting_test.dart` — 6 tests: the stored value + platform channel, and that the row is present in the PDF and CBZ sheets too.

`flutter test`: 389 passed, 2 failed — both pre-existing in
`test/modules/profile/settings_screen_revenue_cat_test.dart` (fail on a clean
tree too). `flutter analyze lib/`: no new errors or warnings.
