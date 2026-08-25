import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/auth_api_service.dart';

/// Drives the network side of the phone → OTP login flow (TZ 2.1/2.3).
/// [PhoneLoginScreen] and [OtpVerifyScreen] each create their own instance
/// (see their `build` methods) so `isLoading`/`errorMessage` reset cleanly
/// between independent attempts instead of leaking across screens.
///
/// Deliberately does *not* persist the session on a successful [verifyLogin]
/// — [OtpVerifyScreen] still has to gate that on the "other device" demo
/// dialog before anything is saved, so the screen calls [AuthSession] itself
/// once it knows the login should actually stick.
class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  /// Triggers the SMS OTP. Returns true on success; on failure sets
  /// [errorMessage] and returns false.
  Future<bool> sendCode(String phone) async {
    _setLoading(true);
    try {
      await AuthApiService.sendCode(phone: phone);
      errorMessage = null;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifies the SMS code. Returns the backend's result (token + user) on
  /// success, or null with [errorMessage] set on failure.
  Future<VerifyLoginResult?> verifyLogin(
      {required String phone,
      required String code,
      required String deviceId}) async {
    _setLoading(true);
    try {
      final result = await AuthApiService.verifyLogin(
          phone: phone, code: code, deviceId: deviceId);
      errorMessage = null;
      return result;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
