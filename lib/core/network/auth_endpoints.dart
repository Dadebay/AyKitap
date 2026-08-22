/// Auth + account endpoints [AuthApiService] calls. Split out of the
/// former single `api_endpoints.dart` (kept the app's whole API surface in
/// one 221-line file) by which service owns each route — see git history
/// for the original if you need it. Paths are relative to
/// [ApiConfig.baseUrl].
class AuthEndpoints {
  AuthEndpoints._();

  // ── Auth (TZ 2.1/2.3) ────────────────────────────────────────────────
  static const String sendCode = '/users/send-code';
  static const String verifyLogin = '/users/verify-login';
  static const String logout = '/users/logout';

  /// PATCH — partial update of the signed-in user (e.g. `{"username": ...}`).
  static const String updateProfile = '/users';

  /// GET — the signed-in user's own record.
  static const String me = '/users/me';

  /// PATCH — pushes the device's current FCM token to the backend.
  static const String fcmToken = '/users/fcm-token';

  /// POST — redeems a promo code (`{"promo_code": "..."}`); the backend
  /// credits the balance server-side and returns an empty `data: {}` — the
  /// caller must follow up with [me] to pick up the new balance.
  static const String promoCodes = '/users/promo-codes';
}
