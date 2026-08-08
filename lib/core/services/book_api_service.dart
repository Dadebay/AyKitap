import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/book_detail.dart';
import '../models/library_book.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the real `/books/*` endpoints — [listBooks] backs
/// [LibraryScreen]'s reading/purchased/liked tabs, [SearchScreen]'s live
/// `search`, [CatalogGenreBooksScreen]'s `genre_id`, and
/// [CatalogAuthorDetailScreen]'s `author_id`, all with real `LibraryBook`s;
/// [likeBook]/[unlikeBook] are called from [BookDetailScreen]'s favorite
/// toggle as a fire-and-forget best-effort sync (the local toggle there is
/// still the UI's actual source of truth).
///
/// [likeBook]/[unlikeBook] 404 for any book id that *didn't* come from
/// [listBooks]/[getBookById] — Home's non-collection sections still show
/// `MockData`'s generated books in places this hasn't reached yet, and a
/// mock `Book.id` (`book_3_7`, ...) has no real book behind it to like.
class BookApiService {
  BookApiService._();

  /// GET `/books/all` — [myBooks]/[bought]/[wantsTo]/[finished] map to the
  /// backend's `my_books`/`bought`/`wants_to`/`finished` filters. The
  /// completed-books shelf combines `my_books=true` with `finished=true`.
  /// [size] is generous
  /// rather than paginated since these are all personal, naturally-small
  /// lists (what the signed-in user is reading/bought/liked), not the full
  /// catalogue.
  ///
  /// [languageIds] are [BookLanguage.id]s from `GET /book-languages` (the
  /// filter page's "Dil" section) and [bookFormats] are the backend's
  /// `book_format` values (`pdf`/`epub`/`cbz`, from the same page's "Format"
  /// section). Both backend params are single-valued, so picking more than
  /// one of either fans out into one request per combination and merges the
  /// responses — see [_listBooksFanOut]. That means [page]/[size] apply
  /// *per request*, not to the merged list.
  static Future<List<LibraryBook>> listBooks({
    bool? myBooks,
    bool? bought,
    bool? wantsTo,
    bool? finished,
    int? authorId,
    int? genreId,
    String? search,
    // Distinct from `search` (which the backend matches against book
    // titles): a substring matched against author *names* instead — see
    // [SearchScreen]'s book/author mode toggle.
    String? authors,
    Iterable<int> languageIds = const [],
    // File formats the book is available in — the backend's `book_format`,
    // which accepts `pdf`, `epub` or `cbz` (see [BookFormatFilter.apiValue]
    // for the filter page's mapping). Single-valued backend side, hence the
    // fan-out above.
    Iterable<String> bookFormats = const [],
    // Publication-year window (the filter page's "Çap senesi" slider) —
    // the backend's `start_year`/`end_year`, matched against each book's
    // `year`. Either end can stand alone as an open-ended bound.
    int? startYear,
    int? endYear,
    // Backend-side ordering — `created_at`/`name`/`year`, paired with
    // [sortOrder] (`ASC`/`DESC`). [SearchScreen]'s default "discover" grid
    // (shown before any search text/filter is entered) passes
    // `created_at`/`DESC` here rather than asking for a random order: the
    // backend dev flagged that true randomization breaks pagination, since a
    // page boundary can't be reproduced across requests without a stable
    // sort underneath it.
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int size = 100,
  }) async {
    final languages = languageIds.toSet();
    final formats = bookFormats.toSet();
    if (languages.length > 1 || formats.length > 1) {
      return _listBooksFanOut(
        languages,
        formats,
        myBooks: myBooks,
        bought: bought,
        wantsTo: wantsTo,
        finished: finished,
        authorId: authorId,
        genreId: genreId,
        search: search,
        authors: authors,
        startYear: startYear,
        endYear: endYear,
        sortBy: sortBy,
        sortOrder: sortOrder,
        page: page,
        size: size,
      );
    }
    try {
      final response =
          await DioClient.instance.get(ApiEndpoints.booksAll, queryParameters: {
        'page': page,
        'size': size,
        if (myBooks == true) 'my_books': true,
        if (bought == true) 'bought': true,
        if (wantsTo == true) 'wants_to': true,
        if (finished == true) 'finished': true,
        if (authorId != null) 'author_id': authorId,
        if (genreId != null) 'genre_id': genreId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (authors != null && authors.isNotEmpty) 'authors': authors,
        if (languages.isNotEmpty) 'language_id': languages.first,
        if (formats.isNotEmpty) 'book_format': formats.first,
        if (startYear != null) 'start_year': startYear,
        if (endYear != null) 'end_year': endYear,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      });
      final items = response.data['data']['items'] as List;
      final books = items
          .map((e) => LibraryBook.fromJson(e as Map<String, dynamic>))
          .toList();
      // Temporary — debugging a report that unliking a book doesn't drop
      // it from `wants_to=true`'s next fetch. `/books/all`'s response body
      // is skipped by ApiLogInterceptor (too large to read), so this is
      // the only visibility into what this call actually returned.
      if (wantsTo == true) {
        log('❤️ wants_to=true -> ${books.length} book(s): ${books.map((b) => b.id).toList()}');
      }
      return books;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Several languages and/or formats selected at once: `language_id` and
  /// `book_format` are both single-valued, so this runs the same query once
  /// per (language, format) combination in parallel and merges the results,
  /// keeping each book once — a book matching two of the selected formats
  /// comes back from both requests.
  static Future<List<LibraryBook>> _listBooksFanOut(
    Set<int> languageIds,
    Set<String> bookFormats, {
    bool? myBooks,
    bool? bought,
    bool? wantsTo,
    bool? finished,
    int? authorId,
    int? genreId,
    String? search,
    String? authors,
    int? startYear,
    int? endYear,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int size = 100,
  }) async {
    // An empty set means "don't constrain this param at all", which is one
    // request with the param omitted — not zero requests.
    final languages = languageIds.isEmpty ? <int?>[null] : languageIds.toList();
    final formats =
        bookFormats.isEmpty ? <String?>[null] : bookFormats.toList();
    final responses = await Future.wait([
      for (final language in languages)
        for (final format in formats)
          listBooks(
            myBooks: myBooks,
            bought: bought,
            wantsTo: wantsTo,
            finished: finished,
            authorId: authorId,
            genreId: genreId,
            search: search,
            authors: authors,
            languageIds: language == null ? const [] : [language],
            bookFormats: format == null ? const [] : [format],
            startYear: startYear,
            endYear: endYear,
            sortBy: sortBy,
            sortOrder: sortOrder,
            page: page,
            size: size,
          )
    ]);
    return _mergeSorted(responses, sortBy: sortBy, sortOrder: sortOrder);
  }

  /// Folds the fan-out's per-request lists back into one, keeping the
  /// requested ordering as far as the client can.
  ///
  /// Each response is already sorted server-side, but the sort has to be
  /// re-applied across responses. `name` and `year` are on [LibraryBook], so
  /// those are sorted exactly. `created_at` isn't returned by the endpoint,
  /// so that case takes the responses round-robin instead: every list is
  /// newest-first already, so interleaving keeps the newest books near the
  /// top rather than letting the first language's whole page sit in front of
  /// the second's.
  static List<LibraryBook> _mergeSorted(
    List<List<LibraryBook>> responses, {
    String? sortBy,
    String? sortOrder,
  }) {
    final byId = <int, LibraryBook>{};
    final longest =
        responses.fold<int>(0, (max, r) => r.length > max ? r.length : max);
    for (var i = 0; i < longest; i++) {
      for (final books in responses) {
        if (i < books.length) byId.putIfAbsent(books[i].id, () => books[i]);
      }
    }
    final merged = byId.values.toList();
    final descending = (sortOrder ?? 'DESC').toUpperCase() == 'DESC';
    int flip(int c) => descending ? -c : c;
    if (sortBy == 'name') {
      merged.sort(
          (a, b) => flip(a.name.toLowerCase().compareTo(b.name.toLowerCase())));
    } else if (sortBy == 'year') {
      merged.sort((a, b) {
        // Books with no year go last either way rather than clumping at
        // whichever end the direction happens to put them.
        if (a.year == null || b.year == null) {
          return a.year == b.year ? 0 : (a.year == null ? 1 : -1);
        }
        return flip(a.year!.compareTo(b.year!));
      });
    }
    return merged;
  }

  /// GET `/books/:id` — one book's full detail.
  static Future<BookDetail> getBookById(int id) async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.bookById(id));
      return BookDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/books/:bookId/progress` — syncs reading progress (0..100)
  /// server-side. [CatalogBookDetailScreen]'s "mark as finished" flag
  /// sends 100, same fire-and-forget best-effort shape as [likeBook].
  static Future<void> updateProgress(int bookId,
      {required int progress}) async {
    try {
      await DioClient.instance.post(ApiEndpoints.bookProgress(bookId),
          data: {'progress': progress});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/books/:bookId/like`.
  static Future<void> likeBook(String bookId) async {
    try {
      await DioClient.instance.post(ApiEndpoints.likeBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE `/books/unlike/:bookId`.
  static Future<void> unlikeBook(String bookId) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.unlikeBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE `/books/bought/:bookId`.
  ///
  /// This only removes the book from the user's purchased-library list; it
  /// deliberately does not delete the catalogue book itself.
  static Future<void> removeBoughtBook(int bookId) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.removeBoughtBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
