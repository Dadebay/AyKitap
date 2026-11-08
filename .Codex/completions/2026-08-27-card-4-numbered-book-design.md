# Card 4 numbered book design

## Outcome

The Flutter client now recognizes backend `card_type: "card_4"` instead of
silently falling back to Card 1. Card 4 renders as a horizontally scrolling
editorial bestseller row inspired by the supplied reference.

## Design

- Large theme-aware rank number behind each real book cover.
- The filled numeral stays behind the cover; a transparent white outline is
  clipped strictly to the cover bounds so the artwork stays visible.
- Web geometry was ported to Flutter: 56% viewport item width, cover offset
  at 22%, 2:3 cover ratio, and 75:100 / 150:100 numeral reserves.
- The Card 4 header has the reference's gradient accent rule.
- Author and title remain beneath the cover.
- Supports light and dark themes, one- and two-digit ranks, missing covers,
  press feedback, book-detail navigation, and the existing See all route.
- A compact variant is used if Card 4 participates in a grouped queue row.

## Files

- `lib/core/models/collection.dart`
- `lib/modules/home/home_screen.dart`
- `lib/modules/home/home_screen_sections.dart`
- `lib/modules/home/widgets/catalog_numbered_book_section.dart`

