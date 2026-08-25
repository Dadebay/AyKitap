import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Persists the bearer token issued after a successful OTP login.
/// Its mere presence is what "being logged in" means in this app: no
/// token in secure storage → no session, regardless of any in-memory UI
/// state — so a killed-and-relaunched app still knows whether it's
/// logged in.
class AuthSession {
  AuthSession._();

  static const _storage = FlutterSecureStorage();
  static const _kBearerToken = 'bearer_token';
  static const _kUserId = 'auth_user_id';
  static const _kPhone = 'auth_phone';
  static const _kName = 'auth_name';
  static const _kAvatar = 'auth_avatar';
  static const _kAvatarImage = 'auth_avatar_image';
  static const _kLastSyncedFcmToken = 'auth_last_synced_fcm_token';

  static Future<void> saveToken(String token, {String? phone}) async {
    await _storage.write(key: _kBearerToken, value: token);
    if (phone != null) await _storage.write(key: _kPhone, value: phone);
  }

  static Future<String?> getToken() => _storage.read(key: _kBearerToken);

  /// The backend's numeric account id from `/users/verify-login`'s
  /// `data.user.id`, kept alongside the bearer token for any future
  /// account-scoped request that needs it.
  static Future<void> saveUserId(int id) =>
      _storage.write(key: _kUserId, value: '$id');

  static Future<int?> getUserId() async {
    final raw = await _storage.read(key: _kUserId);
    return raw == null ? null : int.tryParse(raw);
  }

  static Future<String?> getPhone() => _storage.read(key: _kPhone);

  static Future<void> saveName(String name) =>
      _storage.write(key: _kName, value: name);

  static Future<String?> getName() => _storage.read(key: _kName);

  /// Index into the preset avatar list ([kProfileAvatars]); -1/absent means
  /// the user hasn't picked one yet, so the placeholder icon is shown.
  static Future<void> saveAvatar(int index) =>
      _storage.write(key: _kAvatar, value: '$index');

  static Future<int> getAvatar() async {
    final raw = await _storage.read(key: _kAvatar);
    return int.tryParse(raw ?? '') ?? -1;
  }

  /// A custom photo the user picked from their device, stored as base64 in
  /// a plain file rather than [_storage] — [FlutterSecureStorage] backs onto
  /// the iOS Keychain, which isn't built for a ~1MB blob (see
  /// [ImageCompressor]'s target): the write can silently fail to persist
  /// past a process restart, which read as the picked photo reverting to
  /// the placeholder every time the app was force-closed and reopened. A
  /// profile photo isn't sensitive the way the bearer token is, so a
  /// regular app-support file is both the fix and the right fit. Takes
  /// precedence over the preset [kProfileAvatars] index when present.
  static Future<void> saveAvatarImage(String base64) async {
    final file = await _avatarImageFile();
    await file.writeAsString(base64, flush: true);
    // Drop any leftover value from before this moved off secure storage —
    // otherwise [getAvatarImage]'s migration fallback would keep re-reading
    // a now-stale copy if the file write above ever failed.
    await _storage.delete(key: _kAvatarImage);
  }

  static Future<String?> getAvatarImage() async {
    final file = await _avatarImageFile();
    if (await file.exists()) return file.readAsString();
    // One-time migration for anyone who picked a photo before this moved
    // off secure storage: if it's still readable, save it into the new
    // file so it stops depending on Keychain surviving a restart.
    final legacy = await _storage.read(key: _kAvatarImage);
    if (legacy != null) await saveAvatarImage(legacy);
    return legacy;
  }

  static Future<void> clearAvatarImage() async {
    await _storage.delete(key: _kAvatarImage);
    final file = await _avatarImageFile();
    if (await file.exists()) await file.delete();
  }

  static Future<File> _avatarImageFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/profile_avatar_image.b64');
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  /// The FCM token last successfully PATCHed to `/users/fcm-token` —
  /// [FirebaseMessagingService] compares against this to skip the request
  /// entirely when the device's token hasn't actually changed.
  static Future<void> saveLastSyncedFcmToken(String token) =>
      _storage.write(key: _kLastSyncedFcmToken, value: token);

  static Future<String?> getLastSyncedFcmToken() =>
      _storage.read(key: _kLastSyncedFcmToken);

  static Future<void> clearToken() async {
    await _storage.delete(key: _kBearerToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kPhone);
    await _storage.delete(key: _kName);
    await _storage.delete(key: _kAvatar);
    // A different account can log in on this same device/token next, and
    // it must not inherit the previous account's photo.
    await clearAvatarImage();
    // Logging out can be followed by a *different* account logging in on
    // this same device/token — that new account still needs its own PATCH
    // to bind the token, so the "already synced" cache can't survive login.
    await _storage.delete(key: _kLastSyncedFcmToken);
  }
}
