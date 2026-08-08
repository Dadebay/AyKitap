import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../network/api_exception.dart';
import 'auth_api_service.dart';

/// Holds the signed-in user's own `GET /users/me` record — [balanceManat]
/// (the wallet every paid action spends from) and [user]'s `subscription`
/// ([SubscriptionService] reads that half).
///
/// The balance is server-owned: topping up (promo code / bank card) and
/// spending (a book, a plan) both happen on the backend, so this never
/// edits it locally — it re-reads it via [refresh] after anything that
/// could have changed it.
class AccountService extends ChangeNotifier {
  AccountService._();
  static final instance = AccountService._();

  AuthUser? _user;
  bool _loading = false;

  AuthUser? get user => _user;
  bool get isLoading => _loading;

  /// Null until the first successful [refresh] — callers show a placeholder
  /// rather than a misleading "0 manat" while it's still unknown.
  int? get balanceManat => _user?.balance;

  /// Re-reads `/users/me`. Best-effort: on failure the last known record is
  /// kept (so a dropped connection doesn't blank out the balance) and the
  /// error is swallowed, since every caller treats this as a background sync.
  Future<void> refresh() async {
    if (_loading) return;
    // No `notifyListeners()` here, before the `await` below — several
    // screens call this straight from `initState` (directly, or via
    // [SubscriptionService.load]), and notifying synchronously at that
    // point can trip Provider's "setState() called during build" if
    // another widget in the same build pass is already listening.
    // `isLoading` isn't rendered anywhere, so nothing is lost by only
    // notifying once this actually resolves.
    _loading = true;
    try {
      _user = await AuthApiService.getMe();
    } on ApiException {
      // Keep whatever was already loaded.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Drops the cached record on logout so the next account doesn't briefly
  /// see the previous one's balance.
  void clear() {
    _user = null;
    notifyListeners();
  }
}
