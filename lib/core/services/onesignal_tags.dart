import '../localization/app_locale.dart';

/// Where the notification permission stands, as OneSignal should see it.
enum NotificationPermissionState {
  granted,
  denied,
  notDetermined;

  /// Snake case rather than [name]'s camel case — tag values are matched as
  /// literal strings when building a OneSignal segment, so they have to be
  /// stable and readable in the dashboard.
  String get tagValue => switch (this) {
        NotificationPermissionState.granted => 'granted',
        NotificationPermissionState.denied => 'denied',
        NotificationPermissionState.notDetermined => 'not_determined',
      };
}

/// The OneSignal tag payload, built as pure data.
///
/// Segmentation is the *only* reason this app sends OneSignal anything about
/// its users, so the set is deliberately closed: coarse buckets and flags,
/// never an identifier or content. Nothing here can be reversed into who the
/// reader is or what they read — no phone number, username, bearer token or
/// device fingerprint, and no book title, note or highlight. The
/// `reader_last` campaign route exists precisely so a "continue reading" push
/// needs none of that: the book is resolved on-device from
/// [LastReadBookStore] when the notification is tapped.
class OneSignalTags {
  OneSignalTags._();

  /// Every key this app ever writes. [OneSignalService.logout] removes all of
  /// them so a second account signing in on the same device can't inherit the
  /// first one's segmentation.
  static const keys = <String>[
    'app_language',
    'current_streak_bucket',
    'has_downloaded_book',
    'subscription_state',
    'notification_permission',
  ];

  static Map<String, String> build({
    required AppLanguageCode language,
    required int currentStreak,
    required bool hasDownloadedBook,
    required bool isPremium,
    required NotificationPermissionState permission,
  }) {
    return <String, String>{
      // The real UI language code, which includes `tr` — the app offers four
      // languages, not the three the campaign brief listed. Sending a Turkish
      // reader's language as `en` would quietly mis-target every
      // language-segmented campaign, and the code is no more personal than
      // the three that were listed.
      'app_language': language.name,
      'current_streak_bucket': streakBucket(currentStreak),
      'has_downloaded_book': hasDownloadedBook.toString(),
      'subscription_state': isPremium ? 'premium' : 'free',
      'notification_permission': permission.tagValue,
    };
  }

  /// Buckets rather than the raw count: a campaign only ever segments on
  /// "just started" vs "on a roll", and the exact number is a finer-grained
  /// behavioural signal than this integration has any reason to hand over.
  static String streakBucket(int streak) {
    if (streak <= 0) return '0';
    if (streak <= 3) return '1_3';
    if (streak <= 6) return '4_6';
    return '7_plus';
  }
}
