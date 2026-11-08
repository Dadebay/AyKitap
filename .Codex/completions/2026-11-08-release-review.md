# Aýkitap release review — 2026-11-08

## Scope

Applied the shared Flutter project completion checklist in an isolated worktree on `codex/aykitap-release-review`. The original `feat/reader-ui` worktree and its existing uncommitted files were left intact. The review branch also carries the 42 reader/tablet commits that already existed on `feat/reader-ui`.

## Completed

- Removed the unused `flutter_pdfview` fork; `pdfrx` remains the PDF engine.
- Made Android release signing fail when private signing properties are absent, and ignored signing files and local Gradle output.
- Resolved analyzer warnings, repaired Settings taps, and updated affected tests.
- Stopped a missing book price from granting free access or showing a 0 TMT checkout. Kept a server-confirmed book purchase successful even when later local refresh work fails.
- Added CI for formatting, analysis, tests, Android debug compilation, and iOS compilation without signing. Its Android job prefetches and verifies the pinned PDFium native archives through GitHub's asset API because the package's direct release download timed out on a hosted runner.
- Rewrote the root README in English with verified store links, development and release instructions; kept the old Turkmen README under `docs/`. Restored the project startup docs required by `AGENTS.md` and filled GitHub About.
- Opened [PR #1](https://github.com/Dadebay/AyKitap/pull/1) to `main` with change details, test results, and release gates.

## Verification

- `dart format --output=none --set-exit-if-changed lib test`: passed.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --timeout 45s`: 441 passed.
- `flutter build apk --debug --no-pub`: passed.
- PDFium prefetch: fetched all three Android archives and verified their upstream SHA-256 digests in a clean temporary directory.
- iOS no-codesign build: passed on the earlier GitHub CI run. The latest PR checks are tracked on PR #1.

## Remaining release gates

See `docs/release-readiness.md`. In particular, account deletion currently clears only the local session; privacy disclosures require review against analytics and messaging SDK behavior; the Android release key properties and Play certificate were not verified; device/backend purchase checks remain. No signed APK or store update was published. Do not present this review branch as a validated store binary.
