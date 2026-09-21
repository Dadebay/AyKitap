import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_locale.dart';
import '../models/genre.dart';
import '../models/library_book.dart';

/// Last-known contents of the Search page's two pre-search rows — the genre
/// chips (`GET /genres/all`) and the discover grid's first page
/// (`GET /books/all`) — kept on disk so the page has something to draw before
/// the network answers, and something to keep drawing if it never does.
///
/// Both rows used to start empty on every open and *stay* empty for the whole
/// session whenever their request failed: `_loadGenres` answered an
/// `ApiException` by setting the chip list to `const []`, which renders as no
/// chips at all rather than as an error. That is the "the genres at the top
/// disappear, they come back if I restart" report — a restart being simply
/// another chance for the request to succeed.
///
/// Deliberately a *placeholder*, not a source of truth. A fresh response
/// replaces what is held here wholesale rather than being merged into it: the
/// server's own first page is the authority on which books exist and in what
/// order, so anything it dropped disappears and anything new arrives, in the
/// order it sent. Merging per id would fight the discover grid's
/// daily-rotating sort (see `_discoverDailySorts`), which reorders the same
/// books legitimately.
class SearchDiscoverCache {
  SearchDiscoverCache._();

  /// Genre names are translated server-side off the `Accept-Language` header
  /// [DioClient] sends, so a cached row belongs to the language it was
  /// fetched in — hence a key per language rather than one shared entry,
  /// which would flash the previous language's chips after a switch.
  static String _genresKey(AppLanguageCode language) =>
      'search_genres_v1_${language.name}';

  static const _booksKey = 'search_discover_books_v1';

  static Future<List<Genre>?> readGenres(AppLanguageCode language) =>
      _read(_genresKey(language), Genre.fromJson);

  static Future<void> writeGenres(
          AppLanguageCode language, List<Genre> genres) =>
      _write(_genresKey(language), genres.map((g) => g.toJson()));

  static Future<List<LibraryBook>?> readBooks() =>
      _read(_booksKey, LibraryBook.fromJson);

  static Future<void> writeBooks(List<LibraryBook> books) =>
      _write(_booksKey, books.map((b) => b.toJson()));

  /// Null — rather than an empty list — when there is nothing usable cached,
  /// so a caller can tell "never cached" apart from "cached, and the answer
  /// really was empty".
  static Future<List<T>?> _read<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(key);
      if (raw == null || raw.isEmpty) return null;
      return raw
          .map((s) => fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // A cache that can't be read is worth nothing and worth breaking
      // nothing: the page falls back to whatever the network returns.
      debugPrint('SearchDiscoverCache read failed ($key): $e');
      return null;
    }
  }

  static Future<void> _write(
      String key, Iterable<Map<String, dynamic>> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          key, entries.map(jsonEncode).toList(growable: false));
    } catch (e) {
      debugPrint('SearchDiscoverCache write failed ($key): $e');
    }
  }
}
