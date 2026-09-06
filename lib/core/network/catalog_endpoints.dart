/// Public catalogue-metadata endpoints — [CollectionApiService],
/// [GenreApiService], [BookLanguageApiService], [AuthorApiService],
/// [BannerApiService]. Split out of the former single `api_endpoints.dart`
/// by which service owns each route. Paths are relative to
/// [ApiConfig.baseUrl].
class CatalogEndpoints {
  CatalogEndpoints._();

  /// GET — themed shelves ("Täze gelenler", ...) with their books, rendered
  /// as Home's stacked collection sections.
  static const String collectionsAll = '/collections/all';

  /// GET — genres, optionally filtered by `?parent_id=`. Backs Search's
  /// genre chip row — tapping one opens `GET /books/all?genre_id=`.
  static const String genresAll = '/genres/all';

  /// GET — the languages books can be written in, each with its name in all
  /// three UI languages. Backs the Filtr sahypasy's "Dil" section; the
  /// picked row's id goes back to `BookEndpoints.booksAll` as `language_id`.
  static const String bookLanguages = '/book-languages';

  /// GET — one author's full detail (name, image, bio). Backs
  /// [CatalogAuthorDetailScreen], reached from a `type: "author"`
  /// collection's avatar row.
  static String authorById(int id) => '/authors/$id';

  /// GET — searches authors by name (`?search=`), paginated, returning each
  /// match's id/image/name/`book_count` directly. Backs Search's "Awtor"
  /// mode — dedicated author matching, unlike `BookEndpoints.booksAll`'s
  /// `authors=` param (which matches against each book's author list and
  /// hands back books, not authors).
  static const String authorsSearch = '/authors/search';

  /// GET — the active promo banners for Home's [BannerCarousel], public
  /// (no auth needed).
  static const String banners = '/banners';
}
