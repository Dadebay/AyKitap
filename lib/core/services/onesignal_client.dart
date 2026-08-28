import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

const _oneSignalOrange = '\x1B[38;5;208m';
const _terminalReset = '\x1B[0m';

/// Debug-only diagnostics with a stable, searchable prefix.
///
/// The emoji keeps the line visible in consoles that strip ANSI colours.
/// Release builds do not print OneSignal identifiers or push-token metadata.
void oneSignalDebugLog(String message) {
  if (!kDebugMode) return;
  debugPrint('$_oneSignalOrange🟠 [OneSignal] $message$_terminalReset');
}

String _maskedIdentifier(String? value) {
  if (value == null || value.isEmpty) return 'YOK';
  if (value.length <= 10) return '${value.substring(0, 2)}***';
  return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
}

/// One OneSignal notification tap, reduced to plain data.
///
/// [OneSignalService] maps this into the app's own `aykitap://` URI space, so
/// nothing downstream of the tap has to know an SDK type.
class OneSignalClickPayload {
  /// OneSignal's own notification id — the dedup key for "this tap has
  /// already been routed" (see [NotificationDedupService]).
  final String? notificationId;

  /// The campaign's `additionalData` — `route`, `bookId`, `campaign`. Never
  /// contains anything the app pushed *into* OneSignal about the reader; see
  /// [OneSignalService.syncTags] for what this app is willing to send.
  final Map<String, dynamic> additionalData;

  const OneSignalClickPayload({
    this.notificationId,
    this.additionalData = const <String, dynamic>{},
  });
}

/// Seam over the OneSignal SDK's static API.
///
/// [OneSignalService] talks to this rather than to `OneSignal.*` directly for
/// one reason: the SDK's statics all reach for a platform channel, which
/// throws `MissingPluginException` under `flutter test`. Routing through an
/// interface is what makes the identity format, the tag payload and the
/// tap→route mapping testable at all — the parts of this integration where a
/// mistake is silent in production (a wrong external id just segments the
/// wrong user) rather than loud.
abstract class OneSignalClient {
  Future<void> initialize(String appId);
  Future<void> login(String externalId);
  Future<void> logout();
  Future<void> addTags(Map<String, dynamic> tags);
  Future<void> removeTags(List<String> keys);

  /// Shows the native permission prompt. [fallbackToSettings] sends a user
  /// who already denied it to the system settings page instead of showing a
  /// prompt the OS would silently swallow.
  Future<bool> requestPermission({required bool fallbackToSettings});

  /// Whether push permission is currently granted. Cheap and synchronous —
  /// the SDK caches it.
  bool get hasPermission;

  /// Resumes push delivery for this device. Prompts for OS permission if it
  /// hasn't been granted — so this is only ever called from an explicit
  /// user action, never at boot.
  Future<void> optIn();

  /// Stops push delivery for this device *regardless of OS permission*.
  ///
  /// This is what makes an in-app notifications switch possible at all: an
  /// app cannot revoke its own OS notification permission, so "off" has to
  /// mean unsubscribing rather than un-permitting.
  Future<void> optOut();

  /// Null until the SDK has finished its lifecycle init, which is why
  /// callers treat null as "not opted out".
  bool? get isOptedIn;

  void addClickListener(void Function(OneSignalClickPayload event) onClick);
}

/// The real SDK. Every method here is a straight pass-through: anything with
/// a decision in it belongs in [OneSignalService], where it can be tested.
class LiveOneSignalClient implements OneSignalClient {
  const LiveOneSignalClient();

  static bool _diagnosticObserversAttached = false;

  @override
  Future<void> initialize(String appId) async {
    oneSignalDebugLog('SDK başlatılıyor | appId=$appId');
    _attachDiagnosticObservers();
    await OneSignal.initialize(appId);
    oneSignalDebugLog('SDK initialize tamamlandı');
    await _logCurrentState('ilk durum');
  }

  @override
  Future<void> login(String externalId) async {
    oneSignalDebugLog('Kullanıcı eşleştiriliyor | externalId=$externalId');
    await OneSignal.login(externalId);
    await _logCurrentState('login sonrası');
  }

  @override
  Future<void> logout() async {
    oneSignalDebugLog('Kullanıcı eşleştirmesi kaldırılıyor');
    await OneSignal.logout();
    await _logCurrentState('logout sonrası');
  }

  @override
  Future<void> addTags(Map<String, dynamic> tags) async {
    await OneSignal.User.addTags(tags);
    oneSignalDebugLog('Etiketler senkronlandı | ${tags.keys.join(', ')}');
  }

  @override
  Future<void> removeTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
    oneSignalDebugLog('Etiketler silindi | ${keys.join(', ')}');
  }

  @override
  Future<bool> requestPermission({required bool fallbackToSettings}) async {
    oneSignalDebugLog(
      'İzin isteniyor | ayarlaraYönlendir=$fallbackToSettings',
    );
    final granted =
        await OneSignal.Notifications.requestPermission(fallbackToSettings);
    oneSignalDebugLog('İzin sonucu | granted=$granted');
    await _logCurrentState('izin sonrası');
    return granted;
  }

  @override
  bool get hasPermission => OneSignal.Notifications.permission;

  @override
  Future<void> optIn() async {
    oneSignalDebugLog('Push opt-in isteniyor');
    await OneSignal.User.pushSubscription.optIn();
    await _logCurrentState('opt-in sonrası');
  }

  @override
  Future<void> optOut() async {
    oneSignalDebugLog('Push opt-out isteniyor');
    await OneSignal.User.pushSubscription.optOut();
    await _logCurrentState('opt-out sonrası');
  }

  @override
  bool? get isOptedIn => OneSignal.User.pushSubscription.optedIn;

  @override
  void addClickListener(void Function(OneSignalClickPayload event) onClick) {
    OneSignal.Notifications.addClickListener((event) {
      oneSignalDebugLog(
        'Bildirim açıldı | notificationId='
        '${_maskedIdentifier(event.notification.notificationId)}',
      );
      onClick(OneSignalClickPayload(
        notificationId: event.notification.notificationId,
        additionalData:
            event.notification.additionalData ?? const <String, dynamic>{},
      ));
    });
    oneSignalDebugLog('Bildirim tıklama dinleyicisi hazır');
  }

  static void _attachDiagnosticObservers() {
    if (_diagnosticObserversAttached) return;
    _diagnosticObserversAttached = true;

    OneSignal.Notifications.addPermissionObserver((permission) {
      oneSignalDebugLog('İzin değişti | granted=$permission');
      unawaited(_logCurrentState('izin observer'));
    });
    OneSignal.User.pushSubscription.addObserver((change) {
      final current = change.current;
      oneSignalDebugLog(
        'Push aboneliği değişti | optedIn=${current.optedIn} '
        '| subscriptionId=${_maskedIdentifier(current.id)} '
        '| fcmToken=${_maskedIdentifier(current.token)}',
      );
    });
    OneSignal.User.addObserver((change) {
      oneSignalDebugLog(
        'OneSignal kullanıcısı değişti '
        '| oneSignalId=${_maskedIdentifier(change.current.onesignalId)} '
        '| externalId=${change.current.externalId ?? 'YOK'}',
      );
    });
    oneSignalDebugLog('İzin, abonelik ve kullanıcı observerları hazır');
  }

  static Future<void> _logCurrentState(String source) async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      final oneSignalId = await OneSignal.User.getOnesignalId();
      final externalId = await OneSignal.User.getExternalId();
      oneSignalDebugLog(
        '$source | permission=${OneSignal.Notifications.permission} '
        '| optedIn=${subscription.optedIn} '
        '| subscriptionId=${_maskedIdentifier(subscription.id)} '
        '| fcmToken=${_maskedIdentifier(subscription.token)} '
        '| oneSignalId=${_maskedIdentifier(oneSignalId)} '
        '| externalId=${externalId ?? 'YOK'}',
      );
    } catch (error) {
      oneSignalDebugLog('$source okunamadı | hata=$error');
    }
  }
}
