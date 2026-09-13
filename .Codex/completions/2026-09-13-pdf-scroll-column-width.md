# PDF: one oversized page no longer blurs (and stutters) the whole book

Reported against `Ata-Gowşudow~Perman-1989` — "this book feels like it
freezes, it doesn't scroll smoothly like other PDFs".

## What is unusual about the file

Not its content. Rendering pages 1, 2, 3, 10, 100, 500 and 900 at phone
resolution took a uniform ~0.2 s each, so no page is pathological. 994 pages
in 2.3 MB is an ordinary text book.

Its *page geometry* is what differs:

| Page | Size |
|---|---|
| 1 | 96 × 142.56 pt (thumbnail cover) |
| 2 | **1414 × 2000 pt** (oversized insert) |
| 3–994 | 419 × 595 pt (ordinary A5 text) |

## Why that made every page render soft

`_layoutPages`'s scroll branch stretched every page to the width of the
widest one:

```dart
final width = pages.fold(0.0, (w, p) => math.max(w, p.width)); // 1414
```

Scroll mode then zooms to fit that column into the viewport, and pdfrx
rasterises a page from its **source** size at `zoom × devicePixelRatio`
(`_paintPages`, pdfrx 2.4.7 `pdf_viewer.dart:1481`). So the column width
decides the resolution of every page in the document:

| | A uniform book | This book (before) |
|---|---|---|
| Column width | 419 (what the book is) | 1414 (one insert) |
| Zoom at a 390 pt viewport | 0.93 | 0.28 |
| Ordinary page rasterised at | 419 × 0.93 × 3 = **1170 px** | 419 × 0.28 × 3 = **347 px** |
| Displayed across | 1170 px — exact | 1170 px — **3.4× stretched** |

992 pages were being drawn at roughly a third of the resolution they were
shown at. That is soft text plus a continuous queue of higher-resolution
re-renders as the reader scrolls, which is what "not smooth" was — the file
was never the problem, the column width was.

## The same outlier also stranded the page in paged mode

Follow-up from the same reader: in "Sahypalap" (paged) the page sat small in
the middle of the screen, while "Dowamly aýlaw" (scroll) filled it properly.

Same cause, different symptom. Paged mode centred each page at its **native**
size inside a slot as wide and as tall as the biggest page:

```dart
final slot = pages.fold(0.0, (w, p) => math.max(w, p.width));    // 1414
final tallest = pages.fold(0.0, (h, p) => math.max(h, p.height)); // 2000
```

pdfrx fits a page by its own layout rect, not by the slot around it —
`alternativeFitScale = min(viewW / rect.width, viewH / rect.height)` in
`pdf_viewer_size_delegate_legacy.dart`. An ordinary 419 pt page laid out at
419 inside a 1414 slot therefore covered under a third of the screen, with
the rest of the slot as empty gutter. Scroll mode looked right only because
it already normalised widths.

Both modes now normalise every page to the same column (still preserving each
page's aspect ratio), so a page *is* the rect pdfrx fits. A uniform book is
unaffected — its median equals its page width, so every rect is exactly what
it was before.

## Fix

`pdfScrollColumnWidth` (new, `@visibleForTesting`, alongside the existing
`initialPdfMarginCropFor` precedent) takes the **median** page width instead
of the maximum. The median is what the book actually is; an outlier — wide
insert or thumbnail cover — is fitted to that column like any other page
rather than dragging the other 993 with it.

The original intent is preserved: pages narrower than the column still stretch
to fill the screen width, which is why scroll mode normalises widths at all.
A book whose pages really are all wide (a webtoon) still gets a wide column —
nothing there is an outlier.

Paged mode is deliberately untouched. Its `slot` is also the maximum width,
but pages keep their native size inside it, so the rasterisation scale is
unaffected; the outlier only widens the gutter, which is cosmetic.

Also unchanged, and worth knowing: the 96 pt cover is now scaled ~4.4× to
fill the column and will look soft on its own. That is one page, and strictly
better than the ~14.7× it got before.

## And the gutter around it was white in night mode

Third report from the same screen: theme set to "Gije", but in paged mode the
page sat in a bright white surround.

`PdfNightModeFilter` inverts everything drawn inside it, and
`PdfViewerParams.backgroundColor` — the gutter pdfrx paints behind the pages —
is inside it. So night mode's `0xFF1C1C1E` reached the screen as a near-white.
The filter's own doc comment asserted the opposite ("the surrounding gutter is
already dark in this mode, so only the pages themselves visibly change"); it
was wrong, and continuous scroll hid it by stacking pages edge to edge with
almost no gutter to see.

`PdfNightModeFilter.preInverted` (new) cancels the filter out, and the page
layer hands the gutter that instead when night mode is on. Alpha is left
alone, matching the filter matrix.

### Then: a white halo, and a gutter that still didn't match the page

Two leftovers once the gutter was dark, both from the same inversion:

* **The halo.** pdfrx's default `pageDropShadow` is `Colors.black54` — a
  shadow on a light gutter, a *white glow* once inverted. Night mode now
  passes `null`: with page and gutter both at #000 there is nothing left for
  it to separate. The other colour modes keep it, restated as
  `_pageDropShadow` so turning it off in one mode doesn't silently adopt
  whatever pdfrx's default becomes later.
* **The mismatch.** The gutter was being given `bg` (`0xFF1C1C1E`), but an
  inverted white page is pure `#000`, so the page read as a slightly
  different shade floating on its own background. The gutter now aims at pure
  black. `bg` still drives the chrome around the viewer, which sits outside
  the filter and should stay on the app's dark surface — only what butts up
  against the page has to match it.

## And finally: the resumed page opened over-zoomed and blurred

Fourth report: reopening the book showed the saved page blurred, and the
screenshot had it overflowing both screen edges with a sliver of the next page
beside it.

`calculateInitialZoom` chose between pdfrx's two fit zooms on `_fitPolicy`:

```dart
(_fitPolicy == PdfFitMode.width || _viewMode == PdfViewMode.scroll)
    ? coverZoom
    : alternativeFitZoom,
```

But `coverZoom` scales to the document's whole bounding box, so what it fits
depends on that box's shape, not on what the reader picked:

* Scroll mode's box is one tall narrow column → covering fits the **width**.
  Correct, and why scroll mode always looked right.
* Paged mode's box is 994 pages **side by side** → covering fits the
  **height**, from a strip hundreds of thousands of points wide. For this
  book: `max(390/424446, 750/638) ≈ 1.17`, so a 435 pt page (with margins)
  was drawn 492 pt wide in a 390 pt viewport — past both edges. And drawn
  larger than the ~1165 px it had been rasterised at, hence blurred.

It surfaced on reopen because that is when the initial zoom is applied; a
pinch during the session hid it until next time.

`pdfInitialZoom` (new, `@visibleForTesting`) now picks on view mode alone:
scroll covers, paged fits the page. Paged mode also *can't* use anything
else — it locks panning to the horizontal axis, so a page taller than the
viewport would have an unreachable bottom edge.

**Consequence worth a decision:** "Sahypa ölçegi" (Ini boýunça / Doly sahypa)
now changes nothing. Scroll mode already ignored it, and paged mode can't
honour "fit width" while panning sideways only. Either hide the control in
these modes, or make "Ini boýunça" also switch paged mode to free panning so
there's a way to reach the bottom of an overflowing page. Left alone here
rather than guessed at.

This is also, in hindsight, what the earlier "page stranded in the middle"
report was: the same `coverZoom` path, which before the layout fix produced
`max(390/1413476, 750/2016) ≈ 0.37` — too small then, too large after. One
bug, two opposite symptoms.

## Changed files

- `lib/modules/reader/views/pdf_reader_screen_layout.dart`
- `test/modules/reader/pdf_scroll_column_width_test.dart` (new, 9 tests)

## Verification

- `flutter test test/modules/reader/` — 68/68 pass.
- The new tests cover the outlier cases both ways and assert the arithmetic
  that actually matters: an ordinary page of the reported book now rasterises
  to within a pixel of its displayed width, where taking the widest page put
  it under a third of it.
- `flutter analyze` on the changed files — clean.
- `flutter test` — 311 pass, 2 fail; both the long-standing
  `settings_screen_revenue_cat_test.dart` failures from the in-progress
  RevenueCat/IAP work.

## Worth checking on the device

Open this book in scroll mode: text should be crisp immediately and scrolling
should match any other PDF. The oversized insert (page 2) now fits the column
instead of defining it, and the cover is scaled up to the same width.
