# Animation foundation and reader motion

Completed the first Codex-owned Shipaton motion batch.

## Implemented

- Added shared Aýkitap motion durations, curves, and reduced-motion handling.
- Added a reusable 0.97 press scale with selection haptics for book and author cards.
- Added the catalogue-detail cover Hero and a calm fade/scale reader route for EPUB, PDF, and CBZ.
- Kept PDF classification and the selected PDF reader on one route so the cover transition is not interrupted.
- Passed catalogue cover artwork into the EPUB chapter sheet.
- Animated reader progress updates over 220 ms without changing the cheap drag/expensive seek split.
- Added staggered seven-day streak flame reveals.
- Stopped the looping streak Lottie when the device requests reduced motion.

## Verification

- All changed Dart files were parsed and formatted with the Dart formatter.
- `git diff --check` passes.
- Flutter build/APK and device verification were intentionally not run, per the user's request.

## Suggested device checks

1. Open a downloaded EPUB, PDF, and CBZ from a catalogue detail page.
2. Pop back from each reader and confirm the reverse cover flight feels natural.
3. Drag and tap the reader progress slider in EPUB and PDF.
4. Open Profile/Streak and confirm the seven flames reveal in sequence.
5. Enable the OS "Reduce motion" accessibility option and repeat the checks.
