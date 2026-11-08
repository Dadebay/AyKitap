import 'dart:async';

import 'package:flutter/foundation.dart';

import '../localization/app_locale.dart';
import 'analytics_service.dart';
import 'app_prefs.dart';
import 'auth_session.dart';
import 'deep_link_service.dart';
import 'downloaded_books_store.dart';
import 'notification_dedup_service.dart';
import 'onesignal_client.dart';
import 'onesignal_tags.dart';
import 'streak_service.dart';
import 'subscription_service.dart';

/// The app's *second* push provider, alongside [FirebaseMessagingService].
///
/// The split is by responsibility, not by preference, and both sides stay:
///
/// * **Firebase** — account, purchase, security and any other transactional
///   push the backend sends directly. It owns the `/users/fcm-token`
///   handshake and stays the delivery path Türkmenistan-side infrastructure
///   is built around.
/// * **OneSignal** — engagement only: continue-reading nudges, streak
///   reminders and Shipaton campaigns, all authored in the OneSignal
///   dashboard rather than by the backend.
///
/// Nothing here may affect the Firebase path or app startup. [initialize] is
/// fire-and-forget from `main()`, every public method swallows its own
/// failures, and a missing app id degrades the whole service to a no-op
/// rather than throwing — a OneSignal outage should be invisible to a reader.
class OneSignalService {
  OneSignalService._({OneSignalClient? client, String? appId})
      : _client = client ?? const LiveOneSignalClient(),
        _appId = appId ?? OneSignalService.appId;

  static final instance = OneSignalService._();

  /// Test seam — a service wired to a fake client, with no global state
  /// shared with [instance]. [appId] is overridable because the real one is a
  /// compile-time constant: the "no app id configured" path can't otherwise
  /// be reached from a test.
  @visibleForTesting
  factory OneSignalService.forTest(OneSignalClient client, {String? appId}) =>
      OneSignalService._(client: client, appId: appId);

  /// Public per OneSignal's own model (it identifies the app, and every
  /// installed copy of the binary carries it), so a dev fallback is safe
  /// here. Secrets are a different matter: the REST API key, the Firebase
  /// service-account JSON and the APNs p8 all stay server-side and must
  /// never reach this repository.
  static const _devAppId = '4c19e5ca-a06e-4124-8115-919cd16c8619';

  static const appId =
      String.fromEnvironment('ONESIGNAL_APP_ID', defaultValue: _devAppId);

  final OneSignalClient _client;
  final String _appId;

  bool _ready = false;
  bool _disabled = false;

  /// The most recent identity intent, held until [initialize] finishes.
  ///
  /// A login can land before the SDK is up — `main()` starts [initialize]
  /// without awaiting it, and a returning user's session is restored at
  /// roughly the same moment. Dropping it would leave that device
  /// permanently anonymous to OneSignal until the next sign-in. Replaced
  /// rather than queued: only the latest intent is meaningful.
  _Identity? _pendingIdentity;

  bool get isReady => _ready;

  /// Whether push permission is granted right now. False while the SDK is
  /// down, which is the safe reading — the Settings row then offers to ask
  /// rather than claiming a permission the app can't confirm.
  bool get hasPermission {
    if (!_ready) return false;
    try {
      return _client.hasPermission;
    } catch (_) {
      return false;
    }
  }

  /// Whether push is actually being delivered to this device: the OS allows
  /// it *and* the user hasn't switched it off in Settings.
  bool get isSubscribed {
    if (!_ready || !hasPermission) return false;
    try {
      // Null while the SDK is still finishing lifecycle init — "unknown" is
      // not "opted out", and reading it as such would flip the Settings
      // switch off for a moment on every launch.
      return _client.isOptedIn ?? true;
    } catch (_) {
      return false;
    }
  }

  NotificationPermissionState get permissionState {
    if (!_ready) return NotificationPermissionState.notDetermined;
    return hasPermission
        ? NotificationPermissionState.granted
        : NotificationPermissionState.denied;
  }

  /// Brings the SDK up. Never throws, never awaited by `main()`.
  ///
  /// Deliberately does *not* request notification permission: both providers
  /// initialising is fine, but the native prompt is shown once, later, from
  /// the app shell — see [NotificationPermissionFlow].
  Future<void> initialize() async {
    if (_ready || _disabled) {
      oneSignalDebugLog(
        'Initialize atlandı | ready=$_ready disabled=$_disabled',
      );
      return;
    }
    if (_appId.isEmpty) {
      _disabled = true;
      oneSignalDebugLog('App ID yok; engagement push devre dışı');
      return;
    }
    oneSignalDebugLog('Servis initialize başladı');
    try {
      await _client.initialize(_appId);
      _client.addClickListener(handleClick);
      _ready = true;
      oneSignalDebugLog('Servis hazır | ready=true');
    } catch (error, stack) {
      _disabled = true;
      oneSignalDebugLog(
        'Initialize BAŞARISIZ (Firebase etkilenmedi) | $error\n$stack',
      );
      return;
    }
    await _flushPendingIdentity();
    await _applyStoredSubscriptionPreference();
    await syncTags();
  }

  /// Re-applies the Settings switch across restarts.
  ///
  /// Only the "off" direction is applied. Opting *in* prompts for OS
  /// permission (see [OneSignalClient.optIn]), and raising a permission
  /// prompt from a boot-time restore is exactly the behaviour the whole
  /// [NotificationPermissionFlow] exists to prevent.
  Future<void> _applyStoredSubscriptionPreference() async {
    try {
      if (await AppPrefs.isNotificationsEnabled()) return;
      await _client.optOut();
    } catch (error) {
      oneSignalDebugLog('Abonelik tercihi geri yüklenemedi | $error');
    }
  }

  /// Turns push delivery on or off for this device. Returns false when the
  /// SDK isn't available to carry the change.
  ///
  /// Persisting the choice is the caller's job ([NotificationPermissionFlow]),
  /// which also owns getting OS permission first when switching on.
  Future<bool> setSubscribed(bool value) async {
    if (!_ready) {
      oneSignalDebugLog('Abonelik değişimi atlandı | servis hazır değil');
      return false;
    }
    try {
      value ? await _client.optIn() : await _client.optOut();
      unawaited(syncTags());
      oneSignalDebugLog('Abonelik tercihi uygulandı | enabled=$value');
      return true;
    } catch (error) {
      oneSignalDebugLog('Abonelik değiştirilemedi | $error');
      return false;
    }
  }

  /// Re-binds whatever session is already on the device. Called at boot so a
  /// returning user keeps their external id without signing in again.
  Future<void> loginCurrentUser() async {
    try {
      final userId = await AuthSession.getUserId();
      if (userId != null) await login(userId);
    } catch (error) {
      oneSignalDebugLog('Mevcut kullanıcı okunamadı | $error');
    }
  }

  /// The backend's numeric account id is the only identifier used here.
  /// Never the phone number, username, bearer token or device fingerprint:
  /// an external id is visible in the OneSignal dashboard and travels with
  /// every campaign, so it has to be an opaque key the backend already owns.
  static String externalIdFor(int userId) => 'user_$userId';

  Future<void> login(int userId) async {
    final identity = _Identity.user(userId);
    if (!_ready) {
      _pendingIdentity = identity;
      oneSignalDebugLog('Login initialize sonrasına kuyruğa alındı');
      return;
    }
    await _apply(identity);
  }

  /// Drops both the identity and every tag this app wrote.
  ///
  /// `logout()` alone hands the device a fresh anonymous user, but clearing
  /// the tags explicitly is what guarantees a second account signing in on
  /// the same device can't be segmented by the first one's streak or
  /// subscription state.
  Future<void> logout() async {
    const identity = _Identity.anonymous();
    if (!_ready) {
      _pendingIdentity = identity;
      oneSignalDebugLog('Logout initialize sonrasına kuyruğa alındı');
      return;
    }
    await _apply(identity);
  }

  Future<void> _flushPendingIdentity() async {
    final pending = _pendingIdentity;
    if (pending == null) return;
    _pendingIdentity = null;
    await _apply(pending);
  }

  Future<void> _apply(_Identity identity) async {
    try {
      final userId = identity.userId;
      if (userId == null) {
        await _client.removeTags(OneSignalTags.keys);
        await _client.logout();
      } else {
        await _client.login(externalIdFor(userId));
      }
    } catch (error) {
      oneSignalDebugLog('Kullanıcı kimliği güncellenemedi | $error');
    }
  }

  /// Pushes the current segmentation tags. Safe to call whenever language,
  /// streak or subscription state changes — a failure here must never reach
  /// the UI or interrupt reading, so it is swallowed.
  Future<void> syncTags() async {
    if (!_ready) return;
    try {
      await _client.addTags(OneSignalTags.build(
        language: AppLocale.instance.current,
        currentStreak: StreakService.instance.currentStreak,
        hasDownloadedBook: DownloadedBooksStore.instance.books.isNotEmpty,
        isPremium: SubscriptionService.instance.isActive,
        permission: permissionState,
      ));
    } catch (error) {
      oneSignalDebugLog('Etiketler senkronlanamadı | $error');
    }
  }

  /// Asks the OS for permission, via OneSignal so the two SDKs never each
  /// raise their own prompt. Returns false when the SDK is unavailable.
  Future<bool> requestPermission({bool fallbackToSettings = false}) async {
    if (!_ready) {
      oneSignalDebugLog('İzin isteği atlandı | servis hazır değil');
      return false;
    }
    try {
      final granted = await _client.requestPermission(
          fallbackToSettings: fallbackToSettings);
      // The answer is itself a tag, so the next campaign can target readers
      // who never enabled push.
      unawaited(syncTags());
      return granted;
    } catch (error) {
      oneSignalDebugLog('İzin isteği başarısız | $error');
      return false;
    }
  }

  /// A tap on a OneSignal notification.
  ///
  /// Deliberately does not touch a Navigator: the campaign's data is handed
  /// to [DeepLinkService], which already owns "which screen does this URI
  /// mean" and the cold-start case where no Navigator exists yet.
  @visibleForTesting
  void handleClick(OneSignalClickPayload event) {
    final id = event.notificationId;
    if (id != null && !NotificationDedupService.instance.claim('os-open:$id')) {
      return;
    }
    final data = event.additionalData;
    final route = data['route'];
    final campaign = data['campaign'];
    unawaited(AnalyticsService.instance.logEvent(
      'notification_opened',
      parameters: <String, Object>{
        'provider': 'onesignal',
        if (campaign is String && campaign.isNotEmpty) 'campaign': campaign,
        if (route is String && route.isNotEmpty) 'route': route,
      },
    ));
    unawaited(DeepLinkService.instance.handleNotificationData(data));
  }
}

/// "Who is this device", as an intent that can outlive an unfinished init.
class _Identity {
  final int? userId;
  const _Identity.user(int this.userId);
  const _Identity.anonymous() : userId = null;
}
