# Fast EPUB chapter navigation

## Completed

- Added TOC-aware next and previous chapter lookup, including chapters that share one XHTML file and duplicate TOC hrefs.
- Added a fast visible page burst (up to 12 page turns / 1.6 seconds) followed by an exact TOC target jump. Each trigger advances at most one TOC entry.
- Added three entry points: a next-chapter toolbar button, long press then upward swipe at the right screen edge, and long press on Android volume keys. Short volume presses still turn one page.
- Placed Settings to the left of Next chapter in the EPUB toolbar, as requested.
- Kept the existing reader controls, opening animation, and appearance features. The connected Android run used `LOW_END=false`.

## Verification

- `flutter test --no-pub test/modules/reader`: 115 passed.
- Targeted `flutter analyze --no-pub --no-fatal-infos`: no errors or warnings; only existing info-level style findings.
- `node --check packages/sakura_epub/lib/assets/webpage/html/epubView.js` and `git diff --check`: passed.
- On connected Samsung SM-A346E, confirmed the next-chapter button, long volume press, short volume press, right-edge gesture, responsive toolbar order, and successive one-entry chapter moves in a real EPUB.

## Limit

The connected phone has about 5.3 GB RAM, so a physical 2 GB device was unavailable for this verification. The page burst is capped to avoid laying out every page in a long chapter.
