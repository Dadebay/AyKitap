import 'package:dio/dio.dart';
import '../models/auth_user.dart';
import '../network/auth_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// The `data` payload of a successful `/users/verify-login` response.
class VerifyLoginResult {
  final String accessToken;
  final AuthUser user;
  const VerifyLoginResult({required this.accessToken, required this.user});
}

/// Talks to the `/users/*` auth endpoints (TZ 2.1/2.3). [ApiEndpoints] is
/// the single place their paths live; this is the single place their
/// request/response shapes do, so [PhoneLoginScreen]/[OtpVerifyScreen] never
/// touch Dio directly.
class AuthApiService {
  AuthApiService._();

  /// Triggers an SMS OTP to [phone]. The same endpoint serves both
  /// registration and login — the backend decides which one it is once
  /// [verifyLogin] comes back.
  static Future<void> sendCode({required String phone}) async {
    try {
      await DioClient.instance
          .post(AuthEndpoints.sendCode, data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Verifies the SMS [code] and completes login/registration. [deviceId]
  /// is the stable per-install id from [DeviceFingerprint] — the backend's
  /// "bir hasap — bir enjam" (one account, one device) check keys off it.
  /// A brand-new account's [AuthUser.username] comes back null, which is
  /// what tells the caller to show the name-entry step.
  static Future<VerifyLoginResult> verifyLogin({
    required String phone,
    required String code,
    required String deviceId,
  }) async {
    try {
      final response = await DioClient.instance.post(
        AuthEndpoints.verifyLogin,
        data: {
          'phone': phone,
          // The backend validates this as a number, not a digit string —
          // sending it as a string 400s with "code must be a number
          // conforming to the specified constraints" even though the value
          // itself (4 digits from OtpCodeRow) is always numeric.
          'code': int.parse(code),
          'clientType': 'mobile',
          'deviceId': deviceId,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return VerifyLoginResult(
        accessToken: data['accessToken'] as String,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Trades a Firebase ID token (email/password, Google or Apple — see
  /// [FirebaseAuthService]) for an Aýkitap session via
  /// `POST /users/firebase-login`. Same response shape and same
  /// null-`username`-means-new-account signal as [verifyLogin], so both
  /// share the [completeBackendLogin] pipeline downstream.
  static Future<VerifyLoginResult> firebaseLogin({
    required String idToken,
    String clientType = 'mobile',
  }) async {
    try {
      final response = await DioClient.instance.post(
        AuthEndpoints.firebaseLogin,
        data: {'idToken': idToken, 'clientType': clientType},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return VerifyLoginResult(
        accessToken: data['accessToken'] as String,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Sets the signed-in user's display name on the backend — called right
  /// after a first-time signup's mandatory name-entry step ([NameEntryScreen]),
  /// so the account has a `username` on the server the moment it exists
  /// locally, not just in [AuthSession].
  static Future<void> updateUsername({required String username}) async {
    try {
      await DioClient.instance
          .patch(AuthEndpoints.updateProfile, data: {'username': username});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Sets the signed-in user's avatar photo on the backend. [imageBase64] is
  /// expected to already be under the upload size limit — [ImageCompressor]
  /// is what [AvatarPickerSheet] runs a freshly-picked photo through before
  /// it ever reaches here, so this call never sees an oversized payload.
  static Future<void> updateImage({required String imageBase64}) async {
    try {
      await DioClient.instance
          .patch(AuthEndpoints.updateProfile, data: {'image': imageBase64});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Tells the backend to end the session. Callers should clear the local
  /// session (see [AuthSession]) regardless of whether this succeeds —
  /// the local token's presence is what "logged in" means to the rest of
  /// the app, so a network failure here must never block logging out.
  static Future<void> logout() async {
    try {
      await DioClient.instance.post(AuthEndpoints.logout);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Redeems a promo code via `POST /users/promo-codes` — the backend
  /// credits the balance server-side. The response body carries no updated
  /// balance (`data: {}`), so callers must follow up with [getMe] (or
  /// [AccountService.refresh]) to see the new number. Throws [ApiException]
  /// for an invalid/already-used code, same as every other call here.
  static Future<void> redeemPromoCode({required String code}) async {
    try {
      await DioClient.instance
          .post(AuthEndpoints.promoCodes, data: {'promo_code': code});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches the signed-in user's own record from `/users/me`.
  static Future<AuthUser> getMe() async {
    try {
      final response = await DioClient.instance.get(AuthEndpoints.me);
      return AuthUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Pushes this device's current Firebase Cloud Messaging token to the
  /// backend so it knows where to deliver push notifications for the
  /// signed-in user. Called by [FirebaseMessagingService] whenever a token
  /// becomes available while logged in.
  static Future<void> updateFcmToken({required String fcmToken}) async {
    try {
      await DioClient.instance
          .patch(AuthEndpoints.fcmToken, data: {'fcm_token': fcmToken});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
