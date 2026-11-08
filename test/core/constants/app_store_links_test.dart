import 'package:aykitap/core/constants/app_store_links.dart';
import 'package:aykitap/core/localization/strings/book_detail_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('book sharing uses the App Store link on Apple platforms', () {
    expect(
      AppStoreLinks.forPlatform(TargetPlatform.iOS),
      'https://apps.apple.com/tm/app/a%C3%BDkitap/id6791177731',
    );
    expect(
      AppStoreLinks.forPlatform(TargetPlatform.macOS),
      AppStoreLinks.ios,
    );
  });

  test('book sharing uses the Google Play link on Android', () {
    expect(
      AppStoreLinks.forPlatform(TargetPlatform.android),
      'https://play.google.com/store/apps/details?id=com.aykitap.aykitap',
    );
  });

  test('share text includes the selected platform link', () {
    final text = BookDetailStrings.shareText(
      'The Alchemist',
      'Paulo Coelho',
      appLink: AppStoreLinks.ios,
    );

    expect(text, contains('The Alchemist'));
    expect(text, endsWith(AppStoreLinks.ios));
  });
}
