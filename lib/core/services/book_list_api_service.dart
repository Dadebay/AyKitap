import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/library_book.dart';
import '../network/api_exception.dart';
import '../network/book_endpoints.dart';
import '../network/dio_client.dart';

part 'book_list_api_fanout.dart';

/// The book listing/search endpoint — split out of [BookApiService] to keep
/// that file under the 200-line limit. Backs
/// [LibraryScreen]'s reading/purchased/liked tabs, [SearchScreen]'s live
/// `search`, [CatalogGenreBooksScreen]'s `genre_id`, and
/// [CatalogAuthorDetailScreen]'s `author_id`, all with real `LibraryBook`s.
class BookListApiService {
  BookListApiService._();

  /// GET `/books/all` — [myBooks]/[bought]/[wantsTo]/[finished] map to the
  /// backend's `my_books`/`bought`/`wants_to`/`finished` filters. The
  /// completed-books shelf combines `my_books=true` with `finished=true`.
  /// [size] is generous
  /// rather than paginated since these are all personal, naturally-small
  /// lists (what the signed-in user is reading/bought/liked), not the full
  /// catalogue.
  ///
  /// [languageIds] are [BookLanguage.id]s from `GET /book-languages` (the
  /// filter page's "Dil" section), [bookFormats] are the backend's
  /// `book_format` values (`pdf`/`epub`/`cbz`, from the same page's "Format"
  /// section), and [genreIds] are [Genre.id]s from `GET /genres/all` (Search's
  /// own chip row and the filter page's "Žanr" section). All three backend
  /// params are single-valued, so picking more than one of any of them fans
  /// out into one request per combination and merges the responses — see
  /// [_listBooksFanOut]. That means [page]/[size] apply *per request*, not to
  /// the merged list.
  static Future<List<LibraryBook>> listBooks({
    bool? myBooks,
    bool? bought,
    bool? wantsTo,
    bool? finished,
    int? authorId,
    Iterable<int> genreIds = const [],
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
    final genres = genreIds.toSet();
    if (languages.length > 1 || formats.length > 1 || genres.length > 1) {
      return _listBooksFanOut(
        languages,
        formats,
        genres,
        myBooks: myBooks,
        bought: bought,
        wantsTo: wantsTo,
        finished: finished,
        authorId: authorId,
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
      final response = await DioClient.instance
          .get(BookEndpoints.booksAll, queryParameters: {
        'page': page,
        'size': size,
        if (myBooks == true) 'my_books': true,
        if (bought == true) 'bought': true,
        if (wantsTo == true) 'wants_to': true,
        if (finished == true) 'finished': true,
        if (authorId != null) 'author_id': authorId,
        if (genres.isNotEmpty) 'genre_id': genres.first,
        if (search != null && search.isNotEmpty) 'search': search,
        if (authors != null && authors.isNotEmpty) 'authors': authors,
        if (languages.isNotEmpty) 'language_id': languages.first,
        if (formats.isNotEmpty) 'book_format': formats.first,
        if (startYear != null) 'start_year': startYear,
        if (endYear != null) 'end_year': endYear,
        // A text `search` ranks by relevance server-side — sending a sort on
        // top of that would fight it, so it's only sent for the sort-driven
        // "discover" grid (no typed query).
        if (sortBy != null && (search == null || search.isEmpty))
          'sort_by': sortBy,
        if (sortOrder != null && (search == null || search.isEmpty))
          'sort_order': sortOrder,
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
}
