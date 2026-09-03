# Asset bundle size audit

Date: 2026-08-28. Scope: `assets/` (Flutter runtime bundle) only — no native
Android/iOS launch-icon assets, no build/APK/AAB/IPA work. Source size only;
a real AAB/IPA measurement still needs `flutter build appbundle
--analyze-size` (see §7).

## 1. Result

| | Before | After | Change |
|---|---|---|---|
| Total `assets/` (source, `du -sh`) | 7.9 MB | 5.3 MB | **-2.6 MB (-33%)** |

Two changes, both zero-risk (proven-unused / proven-duplicate, every
reference migrated and verified):

1. **`assets/images/aykitap-play-screenshot-01.png` (2.62 MB) moved out of
   the bundle**, not deleted — now at
   [`docs/store-assets/aykitap-play-screenshot-01.png`](../docs/store-assets/aykitap-play-screenshot-01.png).
   `grep -rn "aykitap-play-screenshot-01" lib/` returned zero hits before the
   move; the only mentions anywhere in the repo were in `.Codex/`
   changelog/TODO docs (`.Codex/completions/2026-08-11-play-screenshot-mockup.md`,
   `.Codex/SHIPATON_2026_REMAINING_TASKS.md:274` — the team's own outstanding
   TODO calling out this exact file). It was Play Store listing artwork that
   should never have shipped inside the app in the first place.
2. **Duplicate logo consolidated (24 KB).** `assets/logo.webp` and
   `assets/images/logo.webp` were byte-identical (confirmed via `shasum`).
   `assets/logo.webp` had exactly one caller
   ([`splash_visuals.dart:79`](../lib/modules/splash/widgets/splash_visuals.dart:79)),
   now repointed to `assets/images/logo.webp` — the same path the other
   three callers (`subscription_required_dialog.dart`,
   `subscription_header.dart`, `gift_hero.dart`) already used. The duplicate
   file is deleted; `assets/images/logo.webp` is the one remaining copy.

Everything else in the inventory below was investigated and **deliberately
left unchanged** — either genuinely needed, or a real but small/risky
opportunity that a full asset-cleanup task (not this one) should own with a
proper native-code audit behind it. Details and reasoning in §3–§6.

## 2. Verification

```
dart format lib/modules/splash/widgets/splash_visuals.dart   # 0 changes needed
flutter analyze lib/modules/splash/widgets/splash_visuals.dart
  test/core/services/asset_bundle_test.dart                  # clean (1 pre-existing
                                                               # directives_ordering info,
                                                               # unrelated to this change)
flutter test test/core/services/asset_bundle_test.dart        # 3/3 passing
flutter test                                                   # 226/226 passing
du -sh assets                                                  # 5.3M (was 7.9M)
```

[`test/core/services/asset_bundle_test.dart`](../test/core/services/asset_bundle_test.dart)
(new) loads the real `AssetManifest` in a `flutter test` run and asserts:
the screenshot is no longer listed, `assets/logo.webp` is gone, `assets/images/logo.webp`
is present and actually loads real bytes, and three unrelated
already-used assets (a Lottie file, a flag, a reader-transition icon) are
still listed — i.e. the pubspec's directory declarations still cover every
asset that's supposed to be there. One thing worth flagging for whoever
re-runs this test later: `flutter test` caches the resolved manifest at
`build/unit_test_assets/AssetManifest.bin`, and on this machine that cache
was stale from before these two file moves — deleting
`build/unit_test_assets/` (or `flutter clean`) forced a fresh regeneration.
If a future asset change doesn't seem to be picked up by a test, that
cache is the first thing to check.

## 3. Full inventory, by category (112 files pre-cleanup)

Category totals below are pre-cleanup; see §1 for the two items removed.

| Category | Size | Files | Verdict |
|---|---|---|---|
| `assets/images/` (incl. onboarding, banks) | ~4.0 MB → ~1.35 MB after cleanup | 18 → 16 | All remaining files runtime-referenced (see §3a) |
| `assets/fonts/` | 2.0 MB | 6 | All genuinely needed — do not touch (§4) |
| `assets/animations/` | 1.5 MB | 6 | All referenced, no embedded images, do not touch (§5) |
| `assets/icons/` (top-level) | 316 KB | 62 | 56 of 62 unreferenced by any grep — **not deleted**, see §3c |
| `assets/icons/reader/` | 24 KB | 6 | All 6 referenced 1:1 by `transition_meta.dart` |
| `assets/flags/` | 60 KB | 5 | All 4 language flags + `.DS_Store` referenced |
| `assets/` (top-level) | — | 1 (`.DS_Store` only, post-cleanup) | See §3b |

### 3a. `assets/images/*.webp` — every remaining file is referenced

Full per-file reference list (already verified via `grep -rn`, one call
site per theme variant unless noted): `author_no_books_{dark,light}.webp` →
`author_no_books_state.dart`; `balance_empty_{dark,light}.webp` →
`insufficient_balance_dialog.dart` + `balance_history_list.dart`;
`book_request_empty_{dark,light}.webp` → `book_suggestions_empty_state.dart`;
`library_empty_{dark,light}.webp` → `library_empty_state.dart`;
`logo.webp` → 4 call sites (see §1); `no_connection_{dark,light}.webp` →
`network_error_state.dart`; `notes_empty_{dark,light}.webp` →
`notes_empty_state.dart`; `search_empty_{dark,light}.webp` →
`search_screen_body.dart`; `shelf_wood.webp` → `shelf_grid.dart`;
`onboarding_{1,2,3}.webp` → `onboarding_screen.dart`; `banks/{halk,rysgal,senagat}.webp`
→ matched dynamically by name substring in `Bank.logoAsset`
(`lib/core/models/bank.dart`) — every bundled bank file has a matching
mapping entry, nothing orphaned.

### 3b. The now near-empty top-level `assets/` pubspec declaration

After removing `assets/logo.webp`, the only file directly under `assets/`
is a stray `.DS_Store` (macOS Finder metadata, ~16 KB, not an asset).
`pubspec.yaml`'s `- assets/` declaration is what makes that top-level
directory scannable at all. **Left in place, not removed**: it costs
nothing (Flutter doesn't bundle dotfiles), and removing it purely to tidy
one now-empty-of-real-content line carries more risk (a future top-level
asset silently not being picked up) than the zero bytes it would save.
Confirmed via `pubspec.yaml`'s own `assets:` list that this is not
duplicate coverage — Flutter's per-directory asset declarations are
**non-recursive**, so `assets/`, `assets/images/`, `assets/fonts/`, etc.
are each independently required for their own files; none of the eight
directory entries in `pubspec.yaml` is redundant with another.

### 3c. `assets/icons/` — 56 of 62 files show zero references anywhere

Every filename under `assets/icons/` (both the `assets/icons/...` form and
the bare filename, in case of a path-building helper) was grepped across
`lib/`, `test/`, and `packages/sakura_epub/`: `a1`–`a13.svg`,
`d1`–`d11.svg`, `m1`–`m5.svg`, `h1`–`h3.svg`, `p1`–`p11.svg` (+ `p1.png`),
`e.svg`, `e1.svg`, `do1.svg`, `do3.svg`, `i1.svg`, `library_f.svg`,
`library_filled.svg`, `bag.svg`, `bag_filled_g.svg`, `search.svg`,
`search_2.svg`, and the loose PNGs `add_to_shelf`, `book_description`,
`content_list`, `font_logo`, `save_my_books`, `theme`, `x` — **zero hits**.
Also checked: none of these are the reader-transition icons (those are a
separate, fully-mapped set of 6 PNGs in `assets/icons/reader/`), and none
are discovered dynamically via `AssetManifest` the way `assets/books/*.epub`
is (the only `AssetManifest`-based dynamic lookup in the app is scoped to
that one folder).

**Not deleted in this pass.** Two reasons: (1) this repo has a
`home_widget`/`home_widget_cli` dev-dependency that generates native
Android/iOS home-screen-widget code outside `lib/` — I did not audit
`android/`/`ios/` native source for references to these icon names, so
"zero hits in `lib/`+`test/`" isn't proof of zero use overall; (2) the
total is 316 KB — real, but small enough that the risk of a wrong guess
outweighs the reward here. This is a genuine 56-file cleanup candidate for
a follow-up task scoped to also grep the native Android/iOS project
directories before deleting anything.

Also confirmed via hash comparison (`shasum` over every file): only two
duplicate pairs exist in the entire `assets/` tree — the logo pair handled
above, and `assets/icons/a10.svg` ⟺ `assets/icons/a13.svg` (both 402
bytes, byte-identical, both part of the 56 unreferenced files above). They
are not a meaningful "merge these" case since neither is used anywhere —
they fall under the same §3c disposition, not a separate action.

## 4. Fonts — no changes; all confirmed necessary

`GilroyRegular` and `Gilroy` intentionally point at the same physical file
(`assets/fonts/Gilroy-Regular.ttf`) in `pubspec.yaml`'s `fonts:` section —
confirmed from the YAML itself, not inferred: Flutter loads **one** 80 KB
file and registers it under two family names, so there is no byte
duplication to fix here, only two live `fontFamily:` strings both actually
used in Dart (`otp_verify_screen.dart`, `phone_login_screen.dart`,
`international_login_screen.dart`, `main.dart`,
`catalog_numbered_book_section.dart`).

`Arial-Regular.ttf` (1.0 MB), `NotoSerif-Regular.ttf` (344 KB),
`SF-Pro-Text-Regular.otf` (304 KB), and `OpenSans-Regular.ttf` (216 KB) are
the reader's 4 selectable fonts (`ReaderFontFamily` enum — exactly 4
values, exactly 4 files, exhaustive switches in
`reader_provider_theme_css.dart`, no unreachable `default:` branch). Each
is used two ways: as a Flutter `fontFamily:` where applicable, and
injected into the EPUB WebView as a base64 `@font-face` for in-book text.
**No subsetting performed**, per the explicit instruction — Arial and
NotoSerif in particular need to keep full Cyrillic/Turkmen glyph coverage
for Russian/Turkmen/Turkish/English reading, and subsetting risks silently
dropping exactly the glyphs a non-Latin reader needs. `Congenial-Medium.otf`
(44 KB) is used once, in `splash_visuals.dart:114`. No `GoogleFonts` usage
anywhere in `lib/` (confirmed via grep), so none of these can be swapped
for a runtime-fetched alternative.

## 5. Lottie animations — no changes; no safe automated win available

All 5 files (`book_idea.json` 944 KB, `streak.json` 288 KB,
`book_reading_boy.json` 224 KB, `Confetti.json` 64 KB,
`no_internet_connection.json` 20 KB) parse as valid JSON and were checked
for Lottie's embedded-raster-image markers (`"e":1` asset entries) and raw
`data:image` URIs — **none found in any of the five**. `book_idea.json`'s
944 KB comes from a single heavily-keyframed vector shape layer at
1920×1920, not an embedded image, so there's no "strip the embedded PNG"
win to take. `book_idea.json` is used in the app's snackbar
(`app_snackbar.dart:87`) and must not be swapped or removed. No Lottie
optimizer tool is installed on this machine and none was installed for
this task (per the no-new-tools instruction), so **no edit was made** to
any of the five files. Re-exporting these from their original animation
source with fewer keyframes is real potential future work, but it needs a
human doing a visual side-by-side afterward — flagging as manual follow-up,
not something to automate here.

## 6. Images — no WebP conversion performed; nothing left to convert

The task allowed converting large runtime-needed raster images to WebP
(tooling: `cwebp` is installed on this machine). Checking the actual
inventory: **every remaining raster image under `assets/images/` is
already `.webp`** — the empty-state pairs, onboarding images, bank logos,
and the logo itself. The only non-WebP raster assets left in the whole
tree are `assets/icons/reader/*.png` (24 KB for all 6 combined — not worth
touching) and the handful of small top-level `assets/icons/*.png` files
(4–8 KB each, and per §3c, unreferenced besides). There was no large
runtime-needed non-WebP image to convert, so this item required no action.

## 7. What this audit does not measure

This is source-tree size only (`du -sh assets`), not a real app-bundle
measurement — Android/iOS packaging, compression, and font subsetting done
by the build tooling itself all change the final number. The next step for
a real before/after comparison is:

```
flutter build appbundle --analyze-size
```

run once on `main` (or this branch's base commit) and once after this
change, comparing the two `flutter build size` reports.

## 8. Dynamic-reference patterns preserved (unaffected by this pass)

Confirmed unaffected, for the record: `SampleBookStore`'s
`AssetManifest`-based `assets/books/*.epub` discovery (no `assets/books/`
directory exists on disk today and none is declared in `pubspec.yaml` —
this is a pre-existing, separate gap, not something this task touches);
`Bank.logoAsset`'s name-substring mapping over `assets/images/banks/*`;
`transition_meta.dart`'s enum-keyed map over `assets/icons/reader/*`;
`language_sheet.dart`'s `assets/flags/*` list; every `isDark ? ...dark.webp
: ...light.webp` theme-selected empty-state image. None of these were
touched.

One correctness note surfaced during the inventory, **not part of this
asset-size task and not acted on here**: `lib/core/data/mock/mock_data.dart`'s
`_coverImages` list hardcodes 16 paths under `assets/images/covers/`, a
directory that does not exist on disk and isn't declared in
`pubspec.yaml` — any code path that reaches it would throw at runtime.
Worth a separate look by whoever owns the mock catalogue data.
