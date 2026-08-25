import 'package:aykitap/core/theme/app_colors.dart';
import 'package:aykitap/core/theme/app_gradients.dart';
import 'package:aykitap/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S3 — Journey tokens. The task's acceptance criteria are "the existing
/// dark/light switch still works", "no colour regression on the old screens"
/// and "the new tokens are named and reusable", so that is what this pins
/// down: the pre-existing getters must return byte-identical values, and the
/// new tokens must genuinely change with the theme rather than handing the
/// light build to both.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // AppTheme.setDark persists through SharedPreferences, so the plugin needs
    // a mock store in a unit test.
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> useDark(bool dark) => AppTheme.instance.setDark(dark);

  group('no regression in the pre-existing palette', () {
    // Hard-coded from the palette as it stood before the Journey tokens were
    // added. If a later change repoints one of these, every old screen shifts
    // colour with it — which is exactly what S3 must not do.
    test('brand and light-mode values are unchanged', () async {
      await useDark(false);
      expect(AppColors.primary, const Color(0xFFE8712C));
      expect(AppColors.primaryDark, const Color(0xFFBF5A1E));
      expect(AppColors.bg, const Color(0xFFF6F6F9));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.card, const Color(0xFFFFFFFF));
      expect(AppColors.border, const Color(0xFFE3E3EA));
      expect(AppColors.white, const Color(0xFF171722));
      expect(AppColors.grey1, const Color(0xFF2E2E3D));
      expect(AppColors.grey2, const Color(0xFF6B6B7C));
      expect(AppColors.grey3, const Color(0xFFB9B9C6));
      expect(AppColors.navBg, const Color(0xFFFFFFFF));
      expect(AppColors.navSelected, const Color(0xFFE8712C));
      expect(AppColors.navUnsel, const Color(0xFFAFAFC0));
    });

    test('dark-mode values are unchanged', () async {
      await useDark(true);
      expect(AppColors.bg, const Color(0xFF13131A));
      expect(AppColors.surface, const Color(0xFF1C1C27));
      expect(AppColors.card, const Color(0xFF242433));
      expect(AppColors.border, const Color(0xFF2E2E42));
      expect(AppColors.white, const Color(0xFFFFFFFF));
      expect(AppColors.grey1, const Color(0xFFE4E4EF));
      expect(AppColors.grey2, const Color(0xFF9191A4));
      expect(AppColors.grey3, const Color(0xFF4A4A5E));
      expect(AppColors.navBg, const Color(0xFF1A1A26));
      expect(AppColors.navUnsel, const Color(0xFF5C5C73));
    });

    test('existing shared gradients are untouched and still const', () {
      expect(AppGradients.coralPurple.colors, [const Color(0xFFF77E68), const Color(0xFFB44BE8)]);
      expect(AppGradients.pdfSpine.colors, [const Color(0xFF6B3B3B), const Color(0xFF2E1919)]);
      expect(AppGradients.epubSpine.colors, [const Color(0xFF3B4A6B), const Color(0xFF191F2E)]);
      expect(AppGradients.cbzSpine.colors, [const Color(0xFF6B4B2E), const Color(0xFF2E2115)]);
    });
  });

  group('Journey tokens match the spec in light mode', () {
    setUp(() => useDark(false));

    test('journeyPrimary is the orange → rose → violet sweep', () async {
      await useDark(false);
      expect(AppGradients.journeyPrimaryColors, [
        const Color(0xFFFF9A3D),
        const Color(0xFFFF5C7D),
        const Color(0xFF8D4DFF),
      ]);
    });

    test('journeySoft is the pastel set', () async {
      await useDark(false);
      expect(AppGradients.journeySoftColors, [
        const Color(0xFFFFE6D5),
        const Color(0xFFFFD8E4),
        const Color(0xFFE8D9FF),
      ]);
    });

    test('journeyRoseViolet and journeySunset are the two-stop cuts', () async {
      await useDark(false);
      expect(
          AppGradients.journeyRoseVioletColors, [const Color(0xFFFF6A88), const Color(0xFFB34BEA)]);
      expect(AppGradients.journeySunsetColors, [const Color(0xFFFFB34D), const Color(0xFFFF5F6D)]);
    });

    test('journeyMist and journeyInk are the specified flats', () async {
      await useDark(false);
      expect(AppColors.journeyMist, const Color(0xFFF8F7FC));
      expect(AppColors.journeyInk, const Color(0xFF22212A));
    });
  });

  group('every Journey token has a distinct dark build', () {
    test('gradients are not the light values reused', () async {
      await useDark(false);
      final light = [
        AppGradients.journeyPrimaryColors,
        AppGradients.journeySoftColors,
        AppGradients.journeyRoseVioletColors,
        AppGradients.journeySunsetColors,
      ];
      await useDark(true);
      final dark = [
        AppGradients.journeyPrimaryColors,
        AppGradients.journeySoftColors,
        AppGradients.journeyRoseVioletColors,
        AppGradients.journeySunsetColors,
      ];
      for (var i = 0; i < light.length; i++) {
        expect(dark[i], isNot(light[i]), reason: 'gradient $i needs its own dark build');
        expect(dark[i].length, light[i].length, reason: 'gradient $i stop count must match');
      }
    });

    test('flat tones flip with the theme', () async {
      await useDark(false);
      final lightMist = AppColors.journeyMist;
      final lightInk = AppColors.journeyInk;
      await useDark(true);
      expect(AppColors.journeyMist, isNot(lightMist));
      expect(AppColors.journeyInk, isNot(lightInk));
    });

    // "Safe in a dark context" is the task's wording; measurably, every dark
    // stop must be darker than the light one it replaces, or it glares on the
    // near-black background instead of reading as colour.
    test('dark stops are darker than their light counterparts', () async {
      await useDark(false);
      final light = [
        ...AppGradients.journeyPrimaryColors,
        ...AppGradients.journeySoftColors,
        ...AppGradients.journeyRoseVioletColors,
        ...AppGradients.journeySunsetColors,
      ];
      await useDark(true);
      final dark = [
        ...AppGradients.journeyPrimaryColors,
        ...AppGradients.journeySoftColors,
        ...AppGradients.journeyRoseVioletColors,
        ...AppGradients.journeySunsetColors,
      ];
      for (var i = 0; i < light.length; i++) {
        expect(dark[i].computeLuminance(), lessThan(light[i].computeLuminance()),
            reason: 'stop $i is not toned down for dark mode');
      }
    });

    // The dark ground has to stay a ground: if it were lighter than the
    // existing dark surfaces it would read as a raised card, not a page.
    test('dark journeyMist stays a background tone', () async {
      await useDark(true);
      expect(
          AppColors.journeyMist.computeLuminance(), lessThan(AppColors.surface.computeLuminance()));
      expect(AppColors.journeyInk.computeLuminance(),
          greaterThan(AppColors.journeyMist.computeLuminance()));
    });
  });

  test('gradients expose their stops for reuse with other geometry', () async {
    await useDark(false);
    expect(AppGradients.journeyPrimary.colors, AppGradients.journeyPrimaryColors);
    expect(AppGradients.journeySoft.colors, AppGradients.journeySoftColors);
    expect(AppGradients.journeyRoseViolet.colors, AppGradients.journeyRoseVioletColors);
    expect(AppGradients.journeySunset.colors, AppGradients.journeySunsetColors);
  });
}
