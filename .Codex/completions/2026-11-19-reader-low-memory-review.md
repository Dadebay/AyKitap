# Reader review and low-memory improvements — 2026-11-19

## Scope

- Preserved the current workspace on `origin/codex/reader-backup-20261119` (`b19c3fb`) before the final review.
- Kept the app-only features in that backup: offline-first reading notes/highlights, a local ten-minute daily goal, and next-book offers using cached catalogue/download data.
- Reviewed EPUB, PDF, and CBZ opening, page controls, animations, progress persistence, and low-memory paths.

## Changes after the backup

- EPUB file sources now encode in a worker isolate without retaining a second raw EPUB byte array in the reader widget. File/read failures reach the existing reader error callback.
- EPUB long-press selection timers are cancelled when another long press starts or the reader closes.
- Note loading preserves queued deletes; notes and delete queues write in mutation order. Background sync catches storage/auth failures; local capture still succeeds if account lookup fails. Pending deletes are hidden from the profile list while awaiting sync.
- The next-book offer refreshes after downloaded books load, handles unavailable download storage, and passes the cached book to the detail screen for offline opening.
- Low-end and reduced-motion modes use a static opening illustration instead of repeating Lottie animations; the reader entrance, swipe hint, and progress scrubber reduce movement.
- Updated reader test fixtures to use a real Flutter Material surface, an embedded test font, and the current page-dwell counting rule. Added durable-notes and daily-goal tests.

## Animation review

| Area | Finding | Result |
| --- | --- | --- |
| Reader entrance (`lib/modules/reader/widgets/reader_entrance.dart:21`) | Cover flight and scale added work while a document was opening. | Low-end uses a short fade. |
| Opening overlays (`lib/modules/reader/widgets/book_opening_overlay.dart:103`, `reader_loading_overlay.dart:33`) | Repeating large Lottie assets competed with EPUB/PDF loading. | Low-end and reduced-motion modes use a static icon. |
| Swipe hint (`lib/modules/reader/widgets/reader_scroll_hint.dart:74`) | One-time hint ran a repeating ticker. | Low-end and reduced-motion modes show a static gesture. |
| Progress scrubber (`lib/modules/reader/widgets/reader_progress_scrubber.dart:170`) | Labels and slider animated during page changes. | Movement is disabled on low-end and reduced-motion devices. |

Verdict: reader movement is retained on capable devices, and the hot opening/page paths use fewer animations on low-memory devices.

## Verification

- 104 reader/recommendation/notes tests passed; two additional focused daily-goal/notes tests passed.
- `flutter analyze --no-pub --no-fatal-infos` completed with no errors or warnings in the reader and touched services. Existing informational lints remain.
- `flutter build apk --debug --dart-define=LOW_END=true` succeeded.
- No Android phone or emulator is attached, so actual 2 GB device memory, frame pacing, and crash behavior remain unmeasured.

## Limitations

- EPUB.js still receives a full base64 book in the WebView. The Dart-side copy was reduced, but very large EPUBs may still exceed a 2 GB device's available memory; an on-device test with representative books is required.
- Existing notes API has no idempotency key. A process death after a successful POST but before local acknowledgement could create a duplicate server note on retry.
