import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';

/// Persists every book's bookmarks (TZ §12.1) in one list, so the reader can
/// show just the open book's marks while the profile lists them all. Same
/// singleton + SharedPreferences shape as [NotesStore].
class BookmarksStore extends ChangeNotifier {
  BookmarksStore._();
  static final instance = BookmarksStore._();

  static const _kKey = 'reading_bookmarks_v1';

  List<Bookmark> _bookmarks = [];
  bool _loaded = false;

  /// Every bookmark, newest first.
  List<Bookmark> get all {
    final sorted = [..._bookmarks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List;
      _bookmarks = decoded
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _loaded = true;
    notifyListeners();
  }

  /// One book's bookmarks, ordered by position in the book so the reader's
  /// list reads top-to-bottom like the book does.
  List<Bookmark> forBook(int bookId) {
    final list = _bookmarks.where((b) => b.bookId == bookId).toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));
    return List.unmodifiable(list);
  }

  bool isBookmarked(int bookId, String cfi) =>
      _bookmarks.any((b) => b.bookId == bookId && b.cfi == cfi);

  /// Adds the page if it isn't marked yet, removes it if it is. Returns true
  /// when a bookmark was added.
  Future<bool> toggle({
    required int bookId,
    required String bookTitle,
    required String cfi,
    required String chapterTitle,
    required double progress,
  }) async {
    if (cfi.isEmpty) return false;
    final existing =
        _bookmarks.where((b) => b.bookId == bookId && b.cfi == cfi).toList();
    if (existing.isNotEmpty) {
      _bookmarks.removeWhere((b) => b.bookId == bookId && b.cfi == cfi);
      await _persist();
      notifyListeners();
      return false;
    }
    _bookmarks.add(Bookmark(
      id: '${bookId}_${DateTime.now().microsecondsSinceEpoch}',
      bookId: bookId,
      bookTitle: bookTitle,
      cfi: cfi,
      chapterTitle: chapterTitle,
      progress: progress,
      createdAt: DateTime.now(),
    ));
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> remove(String id) async {
    _bookmarks.removeWhere((b) => b.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kKey, jsonEncode(_bookmarks.map((b) => b.toJson()).toList()));
  }
}
