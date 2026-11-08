import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_book.dart';

/// When each catalogue book's reader was last opened on this device, so the
/// Kitaplygym shelves can put the book you were last in at the top.
///
/// None of the shelves could do that on their own. The API-backed ones
/// (`GET /books/all`) render whatever order the backend returns, which is by
/// the server's own field, not by what this device did;
/// [DownloadedBooksStore] is ordered by when a file was *downloaded*; and
/// [LastReadBookStore] only ever remembers a single book. This is the one
/// record of "opened, and when", kept per book.
///
/// Local on purpose. It describes this device's reading, and a reader who
/// opens the same account on a second device should see that device's own
/// recency rather than one merged history.
class BookOpenHistory extends ChangeNotifier {
  BookOpenHistory._();
  static final instance = BookOpenHistory._();

  static const _kKey = 'book_open_history_v1';

  /// Bounds the entry so a heavy reader's history can't grow without limit.
  /// Far beyond any shelf's length — the oldest entries fall off the end,
  /// and a book with no entry simply sorts after the ones that have one.
  static const _maxEntries = 500;

  /// Book id → epoch milliseconds of its last open.
  Map<int, int> _openedAt = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _openedAt = {
          for (final entry in decoded.entries)
            if (int.tryParse(entry.key) case final id?)
              if (entry.value case final int at) id: at,
        };
      }
    } catch (e) {
      // A history that can't be read costs nothing but the ordering — the
      // shelves fall back to the order they were already given.
      debugPrint('BookOpenHistory load failed: $e');
      _openedAt = {};
    }
    _loaded = true;
    notifyListeners();
  }

  DateTime? openedAt(int bookId) {
    final at = _openedAt[bookId];
    return at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
  }

  /// Called from [LastReadBookStore.recordOpened] — the app's single "a book's
  /// reader is opening" event, so no call site has to remember this
  /// separately.
  Future<void> recordOpened(int bookId, {DateTime? at}) async {
    await load();
    _openedAt[bookId] = (at ?? DateTime.now()).millisecondsSinceEpoch;
    if (_openedAt.length > _maxEntries) {
      final oldestFirst = _openedAt.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final entry
          in oldestFirst.take(_openedAt.length - _maxEntries).toList()) {
        _openedAt.remove(entry.key);
      }
    }
    await _persist();
    notifyListeners();
  }

  /// [books] most-recently-opened first.
  ///
  /// Books never opened on this device keep the order they arrived in, after
  /// the ones that were — a shelf is still whatever the backend (or the
  /// download store) says it is; this only lifts what the reader actually
  /// came back to. Stable by construction: `List.sort` makes no such promise,
  /// and an unstable sort here would let untouched books shuffle between
  /// rebuilds for no visible reason.
  List<LibraryBook> sortByRecency(List<LibraryBook> books) {
    final indexed = books.indexed.toList()
      ..sort((a, b) {
        final aAt = _openedAt[a.$2.id];
        final bAt = _openedAt[b.$2.id];
        if (aAt == null && bAt == null) return a.$1.compareTo(b.$1);
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        final byRecency = bAt.compareTo(aAt);
        return byRecency != 0 ? byRecency : a.$1.compareTo(b.$1);
      });
    return [for (final (_, book) in indexed) book];
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kKey,
        jsonEncode({
          for (final entry in _openedAt.entries) '${entry.key}': entry.value,
        }),
      );
    } catch (e) {
      debugPrint('BookOpenHistory save failed: $e');
    }
  }
}
