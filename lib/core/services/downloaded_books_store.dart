import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_book.dart';

/// Persists Kitaplygym's "Ýüklenenler" (Downloaded) list across restarts —
/// there's no backend endpoint for this (unlike the Reading/Purchased/
/// Favorites tabs, which are `/books/all` filters), so the catalogue book's
/// own data is kept locally instead, in a plain hidden app-storage file the
/// user never sees directly ([SharedPreferences], same as [NotesStore]/
/// [BookmarksStore]/[OwnBooksStore]).
class DownloadedBooksStore extends ChangeNotifier {
  DownloadedBooksStore._();
  static final instance = DownloadedBooksStore._();

  static const _kKey = 'downloaded_books_v1';

  List<LibraryBook> _books = [];
  bool _loaded = false;

  List<LibraryBook> get books => List.unmodifiable(_books);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const [];
    _books = raw.map((s) => LibraryBook.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    _loaded = true;
    notifyListeners();
  }

  bool isDownloaded(int bookId) => _books.any((b) => b.id == bookId);

  /// Marks [book] as downloaded — newest first, replacing any existing entry
  /// for the same id (e.g. if it was downloaded again after an update).
  Future<void> add(LibraryBook book) async {
    await load();
    _books = [book, ..._books.where((b) => b.id != book.id)];
    await _persist();
    notifyListeners();
  }

  Future<void> remove(int bookId) async {
    await load();
    _books = _books.where((b) => b.id != bookId).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, _books.map((b) => jsonEncode(b.toJson())).toList());
  }
}
