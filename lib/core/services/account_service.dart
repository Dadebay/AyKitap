import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../network/api_exception.dart';
import 'auth_api_service.dart';

/// Holds the signed-in user's own `GET /users/me` record — chiefly
/// [balanceManat], the wallet every paid action in the app spends from
/// (a subscription plan, or a single book).
///
/// The balance is server-owned: topping up (promo code / bank card) and
/// spending both happen on the backend, so this never edits it locally —
/// it re-reads it via [refresh] after anything that could have changed it.
/// That's deliberately unlike [StreakService], whose own `balanceManat` is
/// a purely on-device number from before this endpoint existed.
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
    _loading = true;
    notifyListeners();
    try {
      _user = await AuthApiService.getMe();
    } on ApiException {
      // Keep whatever was already loaded.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Locally decrements the cached balance by [amount] — for the purely
  /// on-device "spends" that have no debit endpoint yet (e.g.
  /// [SubscriptionService.subscribe]). A no-op with no user loaded or a
  /// non-positive amount. The real number wins again on the next [refresh].
  void debitBalance(int amount) {
    final current = _user;
    if (current == null || amount <= 0) return;
    _user = AuthUser(id: current.id, phone: current.phone, username: current.username, image: current.image, balance: current.balance - amount);
    notifyListeners();
  }

  /// Drops the cached record on logout so the next account doesn't briefly
  /// see the previous one's balance.
  void clear() {
    _user = null;
    notifyListeners();
  }
}
