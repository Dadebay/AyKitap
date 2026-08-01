# Home Screen — Collections & Card Types

This document describes the data contract and rendering rules behind the
mobile app's Home screen, so the same layout logic can be reproduced on the
website. It's a spec of *behavior*, not Flutter code — every rule below is
described in plain terms so it can be implemented in React/Vue/whatever the
website uses.

## Endpoint

```
GET {baseUrl}/collections/all
```

Returns an ordered list of "collections" — themed shelves like *"Täze
gelenler"* (New arrivals), *"Hepdelik iň köp okalanlar"* (Most read this
week), or *"Rus Ýazarlar"* (Russian authors). The Home page is built by
rendering this list top to bottom, in the order the backend returns it. No
client-side sorting.

Images referenced anywhere in this payload (`image` fields) are paths like
`/public/foo-12345.jpg`, **not** full URLs. Resolve them against the media
host:

```
{ imagePath.startsWith('http') ? imagePath : mediaBaseUrl + imagePath }
```

`mediaBaseUrl` is a *different host/port* than the API itself (the API is
typically on port 4000, uploaded media is served from port 9000 on the same
host) — confirm the exact value with the backend team per environment.

## Response shape

```jsonc
{
  "statusCode": 200,
  "message": "success",
  "data": [
    {
      "id": 22,
      "type": "author",              // "book" | "author"
      "card_type": "card_1",         // "card_1" | "card_2" | "card_3"
      "name": "Rus Ýazarlar",
      "sub_title": "Rus edebiýatynyň ussatlary", // nullable, may not exist yet
      "queue_position": 41,          // sort/grouping key, see below
      "books": [ /* Book[], see below — EMPTY/IGNORED when type is "author" */ ],
      "authors": [ /* Author[], see below — only present when type is "author" */ ]
    }
  ]
}
```

| Field             | Type                 | Notes                                                                                                    |
| ----------------- | -------------------- | --------------------------------------------------------------------------------------------------------- |
| `id`              | number               | Collection id.                                                                                             |
| `type`            | `"book"` \| `"author"` | See [Collection type](#1-collection-type-book-vs-author).                                                 |
| `card_type`       | `"card_1"` \| `"card_2"` \| `"card_3"` | See [Card types](#2-card-types-for-type-book). Unknown/missing values must fall back to `card_1` — never throw/crash on an unrecognized value, since the backend may add new ones later. |
| `name`            | string               | Section title.                                                                                             |
| `sub_title`       | string \| null       | Section subtitle, shown under the title when present. Optional — omit the subtitle line entirely when null/empty, don't render an empty line. |
| `queue_position`  | number               | See [Queue position grouping](#3-queue-position-grouping).                                                |
| `books`           | Book[]               | **Ignore/skip parsing this entirely when `type` is `"author"`** — it may still be present in the payload but is never rendered for author collections. |
| `authors`         | Author[] \| null     | Only meaningful when `type` is `"author"`.                                                                |

### Book object (inside `books[]`)

```jsonc
{
  "id": 5,
  "name": "Ötanazi okulu 4",
  "image": "/public/otanazi-okulu-4-...png",
  "year": 2023,
  "age": 15,
  "authors": [
    { "id": 1, "name": "Maral Atmaca", "image": "/public/maral-atmaca-...png" }
  ]
}
```

This is a *summary* shape (no `description`, `price`, `page_count` here —
those only come back from the single-book detail endpoint). `authors` is an
array because a book can have co-authors; when rendering a byline, join all
names with `", "`.

### Author object (inside `authors[]`)

```jsonc
{ "id": 2, "name": " Fýodor Mihaýlowiç Dostoýewskiý", "image": "/public/dostoyevsiy-...png" }
```

Same shape whether it appears inside a book's `authors[]` or a collection's
top-level `authors[]`.

---

## 1. Collection type (`book` vs `author`)

- **`type: "book"`** — a themed set of books. Rendered per `card_type` (below).
- **`type: "author"`** — a themed set of authors (e.g. "Rus Ýazarlar"). Always
  rendered as a horizontally-scrolling row of **author avatar chips**
  (circular photo + name underneath), regardless of `card_type`. The `books`
  array on an author-type collection is not read at all — don't even bother
  parsing it.
- If `type: "author"` but `authors` is empty/missing, render nothing for that
  collection (skip it, don't show an empty section with just a header).
- If `type: "book"` but `books` is empty, also render nothing.

## 2. Card types (for `type: "book"`)

### `card_1` — Book row (default)

The plain, most common layout: a section header (title + optional subtitle +
optional "See all" link) followed by a **horizontally-scrolling row of book
cards**. Each book card is:

- Cover image (portrait aspect ratio, ~0.62 width:height), rounded corners,
  soft drop shadow.
- Book title below the cover, 1 line, ellipsis-truncated.
- Author name(s) below the title, 1 line, ellipsis-truncated, muted/secondary
  text color.

This same book-card component is reused everywhere in the app a real book
needs to be shown in a list/grid (an author's book grid, a collection's "see
all" grid, etc.) — one consistent card design site-wide, not a special one
per screen.

### `card_2` — Ranked shelf card

A single card (not a scrolling row of many) shaped like a small "chart":

- Top: a banner strip (~84px tall) using the **first book's own cover image**
  as the background (collections have no dedicated banner image of their
  own), with a top-to-bottom black gradient scrim so white title text stays
  legible. The collection's `name` (and `sub_title` if present) is overlaid
  bottom-left of this banner in white.
- Below the banner: up to the **first 4 books**, each shown as a ranked list
  row — rank number (1–4), small thumbnail, title + author.
- If the collection has more than 4 books, a "See more" outlined button at
  the bottom opens the full book list for that collection.
- The whole thing sits in a rounded-corner card with a solid background
  color (theme's card/surface color).

### `card_3` — Series-style hero card

A single big image card:

- Full-bleed cover image (the **first book's own cover**, again — no
  dedicated collection cover) filling a tall rounded-corner card.
- A frosted-glass ("backdrop blur") panel pinned to the bottom edge of the
  card, tinted semi-transparent black, containing the collection `name`
  (up to 2 lines) and a book-count line ("`N` kitap").
- Tapping the whole card opens the collection's full book list.

### Fallback rule

Any `card_type` value that isn't recognized (including missing/null) must be
treated as `card_1`. Never let an unexpected value break rendering.

## 3. Queue position grouping

`queue_position` is primarily a sort key, but it has a second meaning:
**consecutive collections that share the same `queue_position` value are
meant to be laid out side-by-side as one horizontally-scrolling row**,
instead of each getting its own full-width stacked section.

Example: if the backend returns four consecutive collections — "Biznes /
Maliýe", "Şahsy Ösüş", "Psihologiýa", "Liderlik" — all with
`queue_position: 41`, those four render as **one row** the user can swipe
through horizontally, each item in that row being its own mini shelf-card
(not a full-width section each).

Algorithm:

1. Walk the collections array in order.
2. Group consecutive items that have the identical `queue_position` into one
   run.
3. A run of length 1 renders as a normal full-width section (per its
   `card_type`, as described in [§2](#2-card-types-for-type-book)).
4. A run of length > 1 renders as a single horizontally-scrolling row; each
   item in the row is a fixed-width tile (e.g. ~320px wide) showing that
   collection's `card_2` or `card_3` visual (a `card_1` collection inside a
   multi-item row still renders using the `card_3`-style big-image tile,
   since a full scrolling book row doesn't fit inside another horizontal
   scroller — pick whichever compact tile shape makes sense for the site's
   own layout; the important part is "compact card, not a nested list").
5. **Do not** re-sort the array or search non-consecutive matches — the
   backend already places same-`queue_position` collections next to each
   other. Only group items that are adjacent in the response.

## Empty / loading states

- While the request is in flight: show skeleton/shimmer placeholders roughly
  matching the `card_1` row shape (a title-bar-sized bar + 3–4 card-shaped
  rectangles in a row) — the real section count/shape isn't known until the
  response lands, so a handful of generic placeholders is enough.
- On request failure: fail soft — treat it the same as "zero collections"
  (render nothing below the banner) rather than showing an error screen. This
  is a content section, not a critical flow.
- Per-collection empty rules are covered in [§1](#1-collection-type-book-vs-author)
  above (skip author collections with no authors, skip book collections with
  no books).
