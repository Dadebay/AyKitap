import 'package:flutter/foundation.dart';

/// Public installation links included when a reader shares a book.
abstract final class AppStoreLinks {
  static const ios = 'https://apps.apple.com/tm/app/a%C3%BDkitap/id6791177731';
  static const android =
      'https://play.google.com/store/apps/details?id=com.aykitap.aykitap';
  static const website = 'https://www.aykitap.com.tm';

  static String forPlatform(TargetPlatform platform) => switch (platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => ios,
        TargetPlatform.android => android,
        _ => website,
      };
}
