# Book detail sticky CTA

- Moved the read/buy action row out of the scroll content and into the
  detail screen's fixed bottom area.
- Preserved live download progress, cancellation, ownership, pricing, and
  iOS purchase-mode behavior.
- Kept secondary removal and missing-file messaging in the scroll content.
- Targeted `flutter analyze lib/modules/book_detail` completed with only seven
  pre-existing info-level lints outside the changed CTA code.
- `git diff --check` passed.
