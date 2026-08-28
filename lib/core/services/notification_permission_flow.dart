import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../widgets/notification_permission_dialog.dart';
import 'app_prefs.dart';
import 'onesignal_service.dart';

/// Owns *when* the app asks for notification permission.
///
/// Neither SDK asks on its own any more: [FirebaseMessagingService.init] no
/// longer requests it at boot and [LocalNotificationsService] no longer sets
/// the iOS `request*Permission` flags. A native prompt arriving on the first
/// frame — over the splash, before the user has read a word about why — is
/// the fastest way to get it denied permanently, and on both platforms a
/// denial is close to irreversible in-app.
///
/// So: one in-app explanation, once, from the app shell, and the native
/// prompt only after the user has said yes to that.
class NotificationPermissionFlow {
  NotificationPermissionFlow._();

  /// How long after the shell's first frame the explanation may appear.
  ///
  /// Long enough that it reads as part of the app rather than a launch
  /// interruption — Home has drawn, its covers have settled, and the user has
  /// had a moment to look at it.
  static const settleDelay = Duration(seconds: 3);

  /// Called once from the app shell. Safe to call again — everything it does
  /// is guarded.
  static Future<void> maybeShow(BuildContext context) async {
    if (await AppPrefs.isNotificationPromptSeen()) return;

    // Already granted (a returning install, or the user enabled it from
    // system settings): there is nothing to explain and nothing to ask.
    if (OneSignalService.instance.hasPermission) {
      await AppPrefs.setNotificationPromptSeen();
      return;
    }

    if (!context.mounted) return;
    final accepted = await showNotificationPermissionDialog(context);

    // Recorded either way. "Häzir däl" is an answer, and a permission prompt
    // that returns every launch is what trains people to dismiss it.
    await AppPrefs.setNotificationPromptSeen();
    if (accepted != true) return;
    await _requestFromOs();
  }

  /// What the Settings switch should read as: on only when the OS allows
  /// push *and* the user hasn't switched it off in the app.
  static Future<bool> isEnabled() async {
    if (!await AppPrefs.isNotificationsEnabled()) return false;
    return OneSignalService.instance.isSubscribed;
  }

  /// Drives the Settings switch. Returns the state it should settle on —
  /// which is not always what was asked for: switching *on* can't succeed if
  /// the OS refuses permission, and the switch has to fall back rather than
  /// lie.
  ///
  /// Switching *off* always succeeds, because it unsubscribes rather than
  /// trying to revoke OS permission — an app can't do the latter.
  static Future<bool> setEnabled(bool enabled) async {
    // Recorded first and regardless: this is the user's intent, and it has
    // to survive a restart even if the SDK isn't up to carry it right now.
    await AppPrefs.setNotificationsEnabled(enabled);
    await AppPrefs.setNotificationPromptSeen();

    if (!enabled) {
      await OneSignalService.instance.setSubscribed(false);
      return false;
    }
    // `fallbackToSettings` matters here: once the OS has recorded a denial it
    // stops showing the prompt at all, so without it the switch would appear
    // to do nothing at all for anyone who said no once.
    final granted = OneSignalService.instance.hasPermission ||
        await _requestFromOs(fallbackToSettings: true);
    if (!granted) {
      await AppPrefs.setNotificationsEnabled(false);
      return false;
    }
    await OneSignalService.instance.setSubscribed(true);
    return true;
  }

  /// Raises exactly one native prompt, through whichever SDK is actually up.
  ///
  /// OneSignal is the intended path — it is the SDK that has to observe the
  /// answer for its own subscription state. But permission is not OneSignal's
  /// to own: Firebase carries the account, purchase and security traffic, and
  /// none of that is deliverable without it either. Routing solely through a
  /// SDK that may have failed to initialise would mean a OneSignal outage
  /// silently costing the user every transactional notification too — exactly
  /// the coupling this integration is supposed to avoid.
  static Future<bool> _requestFromOs({bool fallbackToSettings = false}) async {
    if (OneSignalService.instance.isReady) {
      return OneSignalService.instance
          .requestPermission(fallbackToSettings: fallbackToSettings);
    }
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      final status = settings.authorizationStatus;
      return status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
      return false;
    }
  }
}
