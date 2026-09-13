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

  /// The in-flight `getMe()` call, if any — [refresh] hands every concurrent
  /// caller this same future instead of a fresh request each. See [refresh]'s
  /// doc comment for why a caller can't just skip its turn and read [_user]
  /// as-is.
  Future<void>? _inFlightRefresh;

  AuthUser? get user => _user;
  bool get isLoading => _loading;

  /// Null until the first successful [refresh] — callers show a placeholder
  /// rather than a misleading "0 manat" while it's still unknown.
  int? get balanceManat => _user?.balance;

  /// Re-reads `/users/me`. Best-effort: on failure the last known record is
  /// kept (so a dropped connection doesn't blank out the balance) and the
  /// error is swallowed, since every caller treats this as a background sync.
  ///
  /// A caller that arrives while another [refresh] is already in flight
  /// *awaits that same call* rather than returning immediately with whatever
  /// [_user] happened to hold before either one started. [ProfileScreen]'s
  /// post-edit sync is exactly the caller that used to get burned by the old
  /// short-circuit: a background refresh (e.g. a streak-reward's
  /// [StreakServiceReporting]) racing a profile save could return instantly
  /// with the *pre-edit* record, which then looked like "the backend
  /// disagrees with what was just saved" and overwrote the fresh local edit
  /// with stale data — on a slower connection (reported on iOS, not
  /// consistently on Android) the two calls are simply more likely to
  /// overlap.
  Future<void> refresh() {
    final inFlight = _inFlightRefresh;
    if (inFlight != null) return inFlight;
    final future = _refresh();
    _inFlightRefresh = future;
    return future;
  }

  Future<void> _refresh() async {
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
      _inFlightRefresh = null;
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
