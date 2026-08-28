# Home book Hero jank

## Result

- Replaced the full-header BackdropFilter with a child-local ImageFiltered blur.
- Reused the existing 650px decoded cover for the blurred backdrop.
- Isolated the blurred backdrop in a RepaintBoundary.

## Verification

- flutter analyze on both changed files
- book_cover_hero_test.dart and card4_hero_test.dart: 8 tests passed
