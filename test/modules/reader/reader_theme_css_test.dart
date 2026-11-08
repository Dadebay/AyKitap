// Reported as: the EPUB reader stretches a cover when the phone is rotated,
// while the PDF reader is fine. Calibre wraps covers as
// `<svg width="100%" height="100%" viewBox="0 0 W H" preserveAspectRatio="none">`,
// so the element takes the viewport's shape and the artwork is mapped onto it
// non-uniformly — unless both sizing axes are left to the viewBox.
import 'package:aykitap/modules/reader/provider/reader_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReaderProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FakeDioAdapter.install();
    provider = ReaderProvider();
  });

  tearDown(() => provider.dispose());

  Map<String, dynamic> rulesFor(String selector) {
    final css = provider.currentEpubTheme.customCss!;
    return Map<String, dynamic>.from(css[selector] as Map);
  }

  group('picture sizing', () {
    test('an svg is sized on both axes, so its viewBox sets the shape', () {
      final svg = rulesFor('svg');

      // Either axis left unset lets Calibre's `height="100%"` attribute
      // through, and the cover takes the viewport's shape instead of its own.
      expect(svg['width'], 'auto');
      expect(svg['height'], 'auto');
    });

    test('an svg is capped the same way an img is', () {
      final svg = rulesFor('svg');

      // The caps are what shrink an oversized cover; they only preserve the
      // ratio while both axes above stay auto.
      expect(svg['max-width'], '100%');
      expect(svg['max-height'], '96vh');
    });

    test('img and svg agree on how a picture is sized', () {
      final img = rulesFor('img');
      final svg = rulesFor('svg');

      // <img> covers never stretched; the two paths should not diverge again.
      for (final property in ['width', 'height', 'max-width', 'max-height']) {
        expect(svg[property], img[property], reason: property);
      }
    });

    test('a cover page is centred without being given a shape', () {
      final cover = rulesFor(
          'body:has(> img:only-child), body:has(> svg:only-child), body:has(> div:only-child > img:only-child), body:has(> div:only-child > svg:only-child)');

      // Flex centring rather than a forced width/height: the box must not
      // impose an aspect ratio on a picture that will stretch to fill it.
      expect(cover['display'], 'flex');
      expect(cover['align-items'], 'center');
      expect(cover['justify-content'], 'center');
      expect(cover.containsKey('width'), isFalse);
    });
  });

  test('every theme carries the same picture rules', () async {
    // epub.js appends to one stylesheet rather than replacing it, so a rule
    // present under one theme and missing under another would linger as
    // whatever the previous theme had set. The theme is read from storage on
    // open — going through `setTheme` here would need a live WebView.
    for (final mode in ReaderThemeMode.values) {
      SharedPreferences.setMockInitialValues({'reader_theme': mode.index});
      final themed = ReaderProvider();
      addTearDown(themed.dispose);
      await themed.initialize(bookId: 1, bookTitle: 'Test');

      final svg = Map<String, dynamic>.from(
          themed.currentEpubTheme.customCss!['svg'] as Map);
      expect(svg['height'], 'auto', reason: '$mode');
      expect(svg['width'], 'auto', reason: '$mode');
    }
  });
}
