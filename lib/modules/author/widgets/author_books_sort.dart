/// How [CatalogAuthorDetailScreen]'s book grid is ordered. Client-side only
/// — the author's books are already fetched in full, so re-sorting locally
/// avoids a round-trip the `/books/all` `sort_by`/`sort_order` params would
/// need.
enum AuthorBooksSort { name, date }
