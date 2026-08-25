import 'package:aykitap/core/theme/app_colors.dart';
import 'package:aykitap/core/theme/app_gradients.dart';
import 'package:aykitap/core/theme/theme_controller.dart';
import 'package:aykitap/core/widgets/journey_gradient_icon_badge.dart';
import 'package:aykitap/modules/profile/widgets/profile_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
  }

  Container outerContainer(WidgetTester tester) => tester.widget<Container>(
        find.descendant(of: find.byType(ProfileEntryCard), matching: find.byType(Container)).first,
      );

  group('plain (default) path — must stay exactly as it always looked', () {
    testWidgets('white card, no border, grey1 title, corner radius in the 16-20dp spec',
        (tester) async {
      await AppTheme.instance.setDark(false);
      var tapped = false;
      await pump(
        tester,
        ProfileEntryCard(
          leading: const SizedBox(width: 40, height: 40),
          title: 'Ayarlar',
          onTap: () => tapped = true,
        ),
      );

      final decoration = outerContainer(tester).decoration as BoxDecoration;
      expect(decoration.color, AppColors.card);
      expect(decoration.border, isNull);
      final radius = (decoration.borderRadius as BorderRadius).topLeft.x;
      expect(radius, inInclusiveRange(16, 20));

      final title = tester.widget<Text>(find.text('Ayarlar'));
      expect(title.style!.color, AppColors.grey1);

      await tester.tap(find.byType(ProfileEntryCard));
      expect(tapped, isTrue);
    });
  });

  group('highlighted path — the book-request CTA\'s existing look, untouched', () {
    testWidgets('orange tint + border + orange title, same as before accentGradient existed',
        (tester) async {
      await pump(
        tester,
        ProfileEntryCard(
          leading: const SizedBox(width: 40, height: 40),
          title: 'Kitap teklif et',
          highlighted: true,
          onTap: () {},
        ),
      );

      final decoration = outerContainer(tester).decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary.withValues(alpha: 0.12));
      expect(decoration.border, isNotNull);

      final title = tester.widget<Text>(find.text('Kitap teklif et'));
      expect(title.style!.color, AppColors.primary);

      // The accent bar is unique to accentGradient — confirms the two paths
      // don't bleed into each other.
      expect(find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 4),
          findsNothing);
    });
  });

  group('accentGradient path — the new subscription-row treatment', () {
    testWidgets('draws a thin left gradient bar instead of a border', (tester) async {
      await AppTheme.instance.setDark(false);
      await pump(
        tester,
        ProfileEntryCard(
          leading: const SizedBox(width: 40, height: 40),
          title: 'Abunelik',
          accentGradient: AppGradients.journeyRoseViolet,
          onTap: () {},
        ),
      );

      // The bar itself: a Positioned strip exactly 4dp wide, pinned to the
      // left edge, filled with the full-strength gradient.
      final barPositioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byWidgetPredicate((w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration?)?.gradient?.colors ==
                  AppGradients.journeyRoseVioletColors),
          matching: find.byType(Positioned),
        ),
      );
      expect(barPositioned.width, 4);
      expect(barPositioned.left, 0);

      // Title picks up the gradient's own leading stop as a solid tint.
      final title = tester.widget<Text>(find.text('Abunelik'));
      expect(title.style!.color, AppGradients.journeyRoseVioletColors.first);
    });

    testWidgets('tap still fires through the gradient-bar layout', (tester) async {
      var tapped = false;
      await pump(
        tester,
        ProfileEntryCard(
          leading: const SizedBox(width: 40, height: 40),
          title: 'Abunelik',
          accentGradient: AppGradients.journeyRoseViolet,
          onTap: () => tapped = true,
        ),
      );
      await tester.tap(find.byType(ProfileEntryCard));
      expect(tapped, isTrue);
    });

    // Regression pin for a real bug: the very first implementation used a
    // Row(crossAxisAlignment: stretch) with the bar as a plain height-less
    // Container. A stretch-aligned Row sizes its cross axis from its
    // non-flexible children FIRST — and that bar had none — so the whole
    // row (and everything the Scaffold's Stack couldn't lay out below it)
    // collapsed to zero height: untappable in the real app, and "Cannot hit
    // test a render box with no size" in the console, even though this same
    // card passed every check above when pumped alone directly under
    // Scaffold. Only reproduced once seated inside an actual ListView
    // alongside sibling rows — a bare Scaffold(body: card) gave the old Row
    // just enough accidental height from Scaffold to mask it. So this pins
    // the exact production shape: several ProfileEntryCards, one of them
    // accented, inside a plain ListView.
    testWidgets('renders with real height and stays tappable inside a ListView of siblings',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ProfileEntryCard(
                  leading: const SizedBox(width: 40, height: 40),
                  title: 'Balans',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ProfileEntryCard(
                  leading: const SizedBox(width: 40, height: 40),
                  title: 'Abunelik',
                  accentGradient: AppGradients.journeyRoseViolet,
                  onTap: () => tapped = true,
                ),
                const SizedBox(height: 12),
                ProfileEntryCard(
                  leading: const SizedBox(width: 40, height: 40),
                  title: 'Soň sazlamalar',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final cards = find.byType(ProfileEntryCard);
      expect(cards, findsNWidgets(3));
      for (final size in tester.widgetList(cards).map((w) => tester.getSize(find.byWidget(w)))) {
        expect(size.height, greaterThan(0));
      }
      // Every title actually painted — nothing below the accented card was
      // starved of layout.
      expect(find.text('Balans'), findsOneWidget);
      expect(find.text('Abunelik'), findsOneWidget);
      expect(find.text('Soň sazlamalar'), findsOneWidget);

      await tester.tap(find.text('Abunelik'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts to the dark-mode build of the gradient automatically', (tester) async {
      await AppTheme.instance.setDark(true);
      await pump(
        tester,
        ProfileEntryCard(
          leading: const SizedBox(width: 40, height: 40),
          title: 'Abunelik',
          accentGradient: AppGradients.journeyRoseViolet,
          onTap: () {},
        ),
      );
      final title = tester.widget<Text>(find.text('Abunelik'));
      // Dark build's first stop, not light's — proves no hardcoded light
      // value leaked into this row.
      expect(title.style!.color, isNot(const Color(0xFFFF6A88)));
      expect(title.style!.color, const Color(0xFFE85B77));
    });
  });

  testWidgets('composes with JourneyGradientIconBadge as leading — the real profile-row shape',
      (tester) async {
    // Mirrors exactly how _buildBalanceEntry/_buildSettingsEntry/etc. in
    // profile_screen_entries.dart build their leading widget now.
    await pump(
      tester,
      ProfileEntryCard(
        leading: const JourneyGradientIconBadge(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedWallet01),
        ),
        title: 'Balans',
        onTap: () {},
      ),
    );
    expect(find.byType(JourneyGradientIconBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
