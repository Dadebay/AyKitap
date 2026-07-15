import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

/// Tracks which mock-catalogue books the user has individually bought
/// (§10.2) — separate from [SubscriptionService], which grants access to
/// everything at once. Stores full [Book] objects, not just ids: there's no
/// backend to re-fetch a book by id from, and [MockData]'s seeded generators
/// don't form a stable global registry a bare id could be looked up in later.
/// Persisted so a purchase survives leaving and reopening [BookDetailScreen],
/// and backs the Library "Satyn Alinanlar" tab.
class PurchasedBooksStore extends ChangeNotifier {
  PurchasedBooksStore._();
  static final instance = PurchasedBooksStore._();

  static const _kKey = 'purchased_books_v1';

  List<Book> _books = [];
  bool _loaded = false;

  List<Book> get purchasedBooks => List.unmodifiable(_books);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const [];
    _books = raw.map((s) => Book.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    _loaded = true;
    notifyListeners();
  }

  bool isPurchased(String bookId) => _books.any((b) => b.id == bookId);

  Future<void> markPurchased(Book book) async {
    await load();
    if (isPurchased(book.id)) return;
    _books = [book, ..._books];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, _books.map((b) => jsonEncode(b.toJson())).toList());
  }
}
