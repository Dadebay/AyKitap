# Reader product feature review — 2026-11-19

## Scope

Reviewed the Flutter reader and adjacent retention flows to propose prioritized product ideas for Aýkitap in Turkmenistan. No application code was changed.

## Existing foundation

- EPUB, PDF, and CBZ reading; offline downloads; imported books.
- Bookmarks, notes/highlights, in-book search, themes, fonts, progress saving, and reading streaks.
- Purchases, subscriptions, gifting, book requests, and reader event analytics.

## Priority recommendations

1. Make notes/highlights and reading state durable offline, with later sync and conflict handling. Catalogue-book note creation currently awaits the backend before local persistence (`lib/modules/reader/views/reader_view_notes.dart`).
2. Add a high-quality Turkmen/Russian/English/Turkish in-reader dictionary and saved vocabulary, with an offline core.
3. Add a clear reading continuation flow: estimated time to chapter end, daily personalized target, and a next-book suggestion after finishing.
4. Pilot professionally narrated Turkmen audiobooks with read/listen position sync, subject to rights and production costs.
5. Add passage-based study tools: explain a selected passage, saved questions/flashcards, and exportable notes, with publisher permission where required.
6. Add opt-in book clubs and shareable reading milestones after the core reader experience is reliable.

## Market context

- Aýkitap Google Play listing: https://play.google.com/store/apps/details?id=com.aykitap.aykitap
- elkitap App Store listing already advertises audiobooks and AI book summaries: https://apps.apple.com/tm/app/elkitap/id6755152607
- EKitap Google Play listing advertises offline reading and collections: https://play.google.com/store/apps/details?id=tm.com.turkmenpost.Ebook
- World Bank 2024 Digital Progress and Trends Report lists 67% 4G+ coverage for Turkmenistan in its country table; this supports prioritizing resilient offline use: https://documents1.worldbank.org/curated/en/099031924192524293/pdf/P180107173682d0431bf651fded74199f10.pdf

## Validation

This was a read-only product review. Suggested success measures: book-open to next-day return, 7/30-day reading retention, reading minutes per active reader, book completion, offline save failures, and audio repeat use.
