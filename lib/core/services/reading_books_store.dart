import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_book.dart';

/// Local shadow of the server's "Okuduklarym" shelf. A book is added as soon
/// as its reader opens, so an active subscriber can return to it in airplane
/// mode even before the next progress report reaches the backend.
class ReadingBooksStore extends ChangeNotifier {
  ReadingBooksStore._();
  static final instance = ReadingBooksStore._();

  static const _kKey = 'reading_books_v1';

  List<LibraryBook> _books = [];
  bool _loaded = false;

  List<LibraryBook> get books => List.unmodifiable(_books);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const [];
    _books = raw
        .map((item) => LibraryBook.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .where((book) => !book.isFinished)
        .toList();
    _loaded = true;
    notifyListeners();
  }

  /// Records a local reader launch. The book stays available until the next
  /// successful server refresh marks it as completed.
  Future<void> recordOpened(LibraryBook book) async {
    await load();
    _books = [book, ..._books.where((item) => item.id != book.id)];
    await _persist();
    notifyListeners();
  }

  /// Reconciles the offline shadow with the authoritative, non-finished
  /// backend list while retaining local launches not yet synced by progress.
  Future<void> mergeFromBackend(Iterable<LibraryBook> books) async {
    await load();
    final fresh = books.where((book) => !book.isFinished).toList();
    final freshIds = fresh.map((book) => book.id).toSet();
    _books = [
      ...fresh,
      ..._books.where((book) => !freshIds.contains(book.id)),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, _books.map((book) => jsonEncode(book.toJson())).toList());
  }
}
