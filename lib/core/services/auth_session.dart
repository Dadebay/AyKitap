import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the bearer token issued after a successful OTP login.
/// Its mere presence is what "being logged in" means in this app: no
/// token in secure storage → no session, regardless of any in-memory UI
/// state — so a killed-and-relaunched app still knows whether it's
/// logged in.
class AuthSession {
  AuthSession._();

  static const _storage = FlutterSecureStorage();
  static const _kBearerToken = 'bearer_token';
  static const _kPhone = 'auth_phone';
  static const _kName = 'auth_name';
  static const _kAvatar = 'auth_avatar';
  static const _kAvatarImage = 'auth_avatar_image';

  static Future<void> saveToken(String token, {String? phone}) async {
    await _storage.write(key: _kBearerToken, value: token);
    if (phone != null) await _storage.write(key: _kPhone, value: phone);
  }

  static Future<String?> getToken() => _storage.read(key: _kBearerToken);

  static Future<String?> getPhone() => _storage.read(key: _kPhone);

  static Future<void> saveName(String name) => _storage.write(key: _kName, value: name);

  static Future<String?> getName() => _storage.read(key: _kName);

  /// Index into the preset avatar list ([kProfileAvatars]); -1/absent means
  /// the user hasn't picked one yet, so the placeholder icon is shown.
  static Future<void> saveAvatar(int index) => _storage.write(key: _kAvatar, value: '$index');

  static Future<int> getAvatar() async {
    final raw = await _storage.read(key: _kAvatar);
    return int.tryParse(raw ?? '') ?? -1;
  }

  /// A custom photo the user picked from their device, stored as base64.
  /// Takes precedence over the preset [kProfileAvatars] index when present.
  static Future<void> saveAvatarImage(String base64) => _storage.write(key: _kAvatarImage, value: base64);

  static Future<String?> getAvatarImage() => _storage.read(key: _kAvatarImage);

  static Future<void> clearAvatarImage() => _storage.delete(key: _kAvatarImage);

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  static Future<void> clearToken() async {
    await _storage.delete(key: _kBearerToken);
    await _storage.delete(key: _kPhone);
    await _storage.delete(key: _kName);
    await _storage.delete(key: _kAvatar);
    await _storage.delete(key: _kAvatarImage);
  }
}
