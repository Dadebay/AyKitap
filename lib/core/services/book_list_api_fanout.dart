part of 'book_list_api_service.dart';

/// [BookListApiService.listBooks]'s multi-language/multi-format/multi-genre
/// fan-out — split out to keep that file under the 200-line limit.
///
/// Several languages, formats and/or genres selected at once: `language_id`,
/// `book_format` and `genre_id` are all single-valued on the backend, so this
/// runs the same query once per (language, format, genre) combination in
/// parallel and merges the results, keeping each book once — a book matching
/// two of the selected genres comes back from both requests.
Future<List<LibraryBook>> _listBooksFanOut(
  Set<int> languageIds,
  Set<String> bookFormats,
  Set<int> genreIds, {
  bool? myBooks,
  bool? bought,
  bool? wantsTo,
  bool? finished,
  int? authorId,
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
  final formats = bookFormats.isEmpty ? <String?>[null] : bookFormats.toList();
  final genres = genreIds.isEmpty ? <int?>[null] : genreIds.toList();
  final responses = await Future.wait([
    for (final language in languages)
      for (final format in formats)
        for (final genre in genres)
          BookListApiService.listBooks(
            myBooks: myBooks,
            bought: bought,
            wantsTo: wantsTo,
            finished: finished,
            authorId: authorId,
            search: search,
            authors: authors,
            languageIds: language == null ? const [] : [language],
            bookFormats: format == null ? const [] : [format],
            genreIds: genre == null ? const [] : [genre],
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
List<LibraryBook> _mergeSorted(
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
