/// Book catalogue/purchase/file endpoints — [BookApiService],
/// [BookFileApiService], [BookPurchaseApiService]. Split out of the former
/// single `api_endpoints.dart` by which service owns each route. Paths are
/// relative to [ApiConfig.baseUrl].
class BookEndpoints {
  BookEndpoints._();

  /// GET — paginated real book catalogue, filtered by query params
  /// (`my_books`, `bought`, `wants_to`, `search`, `genre_id`, ...). Backs
  /// [LibraryScreen]'s reading/purchased/liked tabs; Search still runs on
  /// `MockData`'s locally-generated `Book.id`s (`book_3_7`, ...), so
  /// [likeBook]/[unlikeBook] below only actually persist for ids that came
  /// from here.
  static const String booksAll = '/books/all';

  /// GET — one book's full detail (description, genres, authors, files).
  /// Backs [CatalogBookDetailScreen] — a real id from [booksAll],
  /// `collectionsAll`, or a banner's `book_id`.
  static String bookById(int id) => '/books/$id';

  /// POST `{"progress": 0..100}` — syncs the signed-in user's reading
  /// progress for [bookId] server-side. [CatalogBookDetailScreen]'s "mark
  /// as finished" flag button sends `100`; nothing else calls this yet
  /// (the readers still track progress purely on-device via prefs).
  ///
  /// DELETE on the same path drops that progress record entirely, which is
  /// what takes a book off *both* progress-backed shelves — `my_books`
  /// (Okaýanlarym) and `my_books`+`finished` (Okap gutaranlarym) are two
  /// views of this one row, so there is deliberately no separate
  /// "un-finish" endpoint. The catalogue book itself is untouched.
  static String bookProgress(int bookId) => '/books/$bookId/progress';

  /// POST — likes [bookId] for the signed-in user.
  static String likeBook(String bookId) => '/books/$bookId/like';

  /// DELETE — un-likes [bookId] for the signed-in user.
  static String unlikeBook(String bookId) => '/books/unlike/$bookId';

  /// DELETE — removes a book from the signed-in user's purchased library.
  static String removeBoughtBook(int bookId) => '/books/bought/$bookId';

  /// POST — buys [bookId] for the signed-in user, paying from the balance.
  /// 201 on success, its `data` a presigned download link for the purchased
  /// file (same `{url, size, name, lastModified}` shape as [bookFile]) — a
  /// bonus the purchase flow doesn't currently use, but is there if a later
  /// change wants to skip the follow-up [bookFile] call right after buying.
  /// 400 with `{"message": "You do not have enough balance", ...}` when the
  /// balance falls short.
  static String buyBook(int bookId) => '/users/buy-book/$bookId';

  /// GET — a presigned download link for one book file. The `?filename=`
  /// value is the `file_key` straight off `GET /books/:id`'s `bookFiles[]`
  /// (`/private/....pdf`); Dio URL-encodes it as a query parameter.
  ///
  /// The returned URL points at the media host (port 9000, not the API's
  /// 4000) and carries an `X-Amz-Expires=600` signature — it is valid for
  /// ~10 minutes and must never be persisted. [BookDownloadService] fetches
  /// a fresh one for every download.
  static const String bookFile = '/books/file';
}
