import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_detail.dart';
import '../network/api_exception.dart';
import 'account_service.dart';
import 'auth_session.dart';
import 'book_api_service.dart';
import 'book_list_api_service.dart';
import 'subscription_service.dart';

/// What the app is allowed to do with a book right now, in the order the
/// rules are applied.
enum BookAccess {
  /// No session at all — both CTAs lead to login first.
  needsLogin,

  /// Bought outright: readable forever, subscription or not.
  purchased,

  /// Covered by an active subscription — readable until it expires.
  subscription,

  /// Not owned, but the balance covers the price.
  needsPurchase,

  /// Not owned and the balance is short — the only way forward is a top-up.
  needsTopUp,
}

/// The single place that decides whether a book can be opened. Screens ask
/// this instead of assembling their own `isLoggedIn && (bought || sub)`
/// conditions, so the precedence — **purchased > subscription > buy >
/// top up** — is written down exactly once.
///
/// The purchased set is cached in [SharedPreferences] so [canRead] can
/// answer with no network at all: a book that was bought and downloaded
/// has to open in airplane mode.
class BookAccessService extends ChangeNotifier {
  BookAccessService._();
  static final instance = BookAccessService._();

  static const _kPurchasedIds = 'purchased_book_ids_v1';

  Set<int> _purchasedIds = {};
  bool _loaded = false;

  Set<int> get purchasedIds => Set.unmodifiable(_purchasedIds);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _purchasedIds = (prefs.getStringList(_kPurchasedIds) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    _loaded = true;
    notifyListeners();
  }

  bool isPurchased(int bookId) => _purchasedIds.contains(bookId);

  /// The offline half of [resolve]: can this book be opened right now,
  /// without asking the backend anything? Used by the reading flow once a
  /// file is already on disk, and by the downloaded shelf's lock badge.
  bool canRead(int bookId) =>
      isPurchased(bookId) || SubscriptionService.instance.isActive;

  /// Full evaluation for [book]'s CTA row. Reads only cached state — the
  /// token, the purchased set, [SubscriptionService], and the last known
  /// balance — so it never blocks on a request.
  Future<BookAccess> resolve(BookDetail book) async {
    await load();
    await SubscriptionService.instance.load();

    if (!await AuthSession.isLoggedIn()) return BookAccess.needsLogin;
    if (isPurchased(book.id)) return BookAccess.purchased;
    if (SubscriptionService.instance.isActive) return BookAccess.subscription;

    final price = book.price ?? 0;
    // A free book has nothing to buy — treat it as already owned rather
    // than sending the user to a 0-manat checkout.
    if (price <= 0) return BookAccess.purchased;

    final balance = AccountService.instance.balanceManat ?? 0;
    return balance >= price ? BookAccess.needsPurchase : BookAccess.needsTopUp;
  }

  /// Re-reads `GET /books/all?bought=true` — the backend is the authority
  /// on what the user owns; the local set is only its offline shadow.
  /// Best-effort: a failed sync leaves the cache alone rather than
  /// blanking out access while offline.
  Future<void> refreshPurchased() async {
    await load();
    if (!await AuthSession.isLoggedIn()) return;
    try {
      final books = await BookListApiService.listBooks(bought: true);
      await replacePurchased(books.map((b) => b.id));
    } on ApiException {
      // Keep the cached set.
    }
  }

  /// Overwrites the cache with a purchased list that was already fetched —
  /// Kitaplygym's "Satyn alnanlar" tab is exactly that request, so it feeds
  /// its own response in here instead of triggering an identical second one.
  Future<void> replacePurchased(Iterable<int> bookIds) async {
    await load();
    _purchasedIds = bookIds.toSet();
    await _persist();
    notifyListeners();
  }

  Future<void> markPurchased(int bookId) async {
    await load();
    if (!_purchasedIds.add(bookId)) return;
    await _persist();
    notifyListeners();
  }

  /// The offline half of `DELETE /books/bought/:id`: the book is no longer
  /// owned, so the cached set must stop granting [canRead] for it (an
  /// already-downloaded file would otherwise keep opening in airplane mode).
  Future<void> removePurchased(int bookId) async {
    await load();
    if (!_purchasedIds.remove(bookId)) return;
    await _persist();
    notifyListeners();
  }

  /// Called on logout — without this the next account on this device would
  /// inherit the previous one's purchases.
  Future<void> clear() async {
    _purchasedIds = {};
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPurchasedIds);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kPurchasedIds, _purchasedIds.map((id) => '$id').toList());
  }
}
