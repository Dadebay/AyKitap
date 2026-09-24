import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigation/root_navigator.dart';
import 'account_service.dart';
import 'auth_session.dart';
import 'book_access_service.dart';
import 'onesignal_service.dart';
import 'purchase_mode_service.dart';
import 'subscription_service.dart';
import '../../modules/auth/phone_login_screen.dart';

/// Reacts to a 401 from any authenticated request ([DioClient]'s `onError`)
/// as the backend having logged this device out from under it — same
/// symptom either way: `GET /users/me`, `GET /books/all?my_books=true`, ...
/// every authenticated call after the token died fails the same way, so
/// whatever screen is open just keeps erroring instead of telling the user
/// what happened.
///
/// Clears the same local session state the "Çykmak" button does
/// ([SettingsScreen]'s `_confirmLogout`), then pushes the login screen so
/// there's a way back in instead of a dead end.
class SessionExpiryHandler {
  SessionExpiryHandler._();
  static final instance = SessionExpiryHandler._();

  // A single revoked token fails every request already in flight at that
  // moment, each landing here within moments of the others — without this,
  // each one would push its own login screen on top of the last.
  bool _handling = false;

  /// [path] and [host] name the request whose 401 caused this. Logged
  /// because a forced re-login is the most disruptive thing the app does to
  /// a signed-in reader, and until now it left no trace of *which* call
  /// decided the session was over — a genuinely expired token and a single
  /// endpoint answering 401 for its own unrelated reason look identical from
  /// the outside. [host] is included because the client fails over to a
  /// second base URL on a connection error (see [DioClient]): a token the
  /// primary host issued being rejected by the fallback would show up here
  /// as a 401 from the other host.
  Future<void> handleUnauthorized({String? path, String? host}) async {
    if (kDebugMode) {
      debugPrint('\x1B[31m\x1B[1m🚪 SESSION 401 — signing out because '
          '"${path ?? "?"}" on "${host ?? "?"}" returned 401\x1B[0m');
    }
    if (_handling) return;
    // Only a session that *was* believed valid counts — a request that
    // simply went out with no token yet (a cold-start race, a deliberately
    // anonymous call) isn't "your session expired", it's just unauthenticated.
    if (await AuthSession.getToken() == null) return;
    _handling = true;
    try {
      await AuthSession.clearToken();
      // Same cache-drop order as a manual logout: the cached /users/me
      // record and this account's purchased/subscription state, so nothing
      // of this session leaks into whoever logs in next on this device.
      AccountService.instance.clear();
      await BookAccessService.instance.clear();
      await SubscriptionService.instance.clear();
      // ...and the engagement provider's identity and tags, so campaigns
      // segmented on this account stop reaching the device.
      await OneSignalService.instance.logout();
      // Ödeme yüzeyi bu hesaba özeldi; oturum gidince yeniden çözülmeli.
      // `/revenuecat/config` artık 401 döneceği için bu çağrı iOS'u güvenli
      // tarafa ("yalnızca App Store") geri alıyor — bir sonraki kullanıcı
      // öncekinin açık kalmış satın alma yüzeyini devralmıyor.
      await PurchaseModeService.instance.refresh();
      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) return;
      await navigator
          .push(MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
    } finally {
      _handling = false;
    }
  }
}
