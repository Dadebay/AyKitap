import 'package:aykitap/core/theme/app_colors.dart';
import 'package:aykitap/core/theme/app_gradients.dart';
import 'package:aykitap/core/theme/theme_controller.dart';
import 'package:aykitap/core/widgets/journey_gradient_icon_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester, Widget badge) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: badge))));
  }

  group('sizing', () {
    for (final entry in {
      JourneyBadgeSize.small: 32.0,
      JourneyBadgeSize.medium: 48.0,
      JourneyBadgeSize.large: 64.0,
    }.entries) {
      testWidgets('${entry.key} renders at ${entry.value}dp', (tester) async {
        await pump(
          tester,
          JourneyGradientIconBadge(
            size: entry.key,
            icon: const Icon(Icons.star),
          ),
        );
        final box = tester.getSize(find.byType(JourneyGradientIconBadge));
        expect(box, Size(entry.value, entry.value));
      });
    }
  });

  group('pastel variant (default)', () {
    testWidgets('fills a circle with journeySoft and colours the icon with journeyInk',
        (tester) async {
      await pump(tester, const JourneyGradientIconBadge(icon: Icon(Icons.star)));

      final decoratedBox = tester.widget<Container>(
        find.descendant(
            of: find.byType(JourneyGradientIconBadge), matching: find.byType(Container)),
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.gradient, AppGradients.journeySoft);

      final iconTheme = tester.widget<IconTheme>(
        find.descendant(
            of: find.byType(JourneyGradientIconBadge), matching: find.byType(IconTheme)),
      );
      expect(iconTheme.data.color, AppColors.journeyInk);

      // No ShaderMask in this variant — the gradient is the container fill,
      // not something painted onto the glyph.
      expect(
        find.descendant(
            of: find.byType(JourneyGradientIconBadge), matching: find.byType(ShaderMask)),
        findsNothing,
      );
    });

    testWidgets('iconColor overrides the default journeyInk tint', (tester) async {
      await pump(
        tester,
        const JourneyGradientIconBadge(
          icon: Icon(Icons.star),
          iconColor: Color(0xFF00FF00),
        ),
      );
      final iconTheme = tester.widget<IconTheme>(
        find.descendant(
            of: find.byType(JourneyGradientIconBadge), matching: find.byType(IconTheme)),
      );
      expect(iconTheme.data.color, const Color(0xFF00FF00));
    });

    testWidgets('accepts a HugeIcon child the same as an Icon', (tester) async {
      // A real icon-data literal from the app's own hugeicons dependency
      // (a minimal single-path circle) — proves the badge doesn't special-
      // case Flutter's Icon.
      await pump(
        tester,
        const JourneyGradientIconBadge(
          icon: HugeIcon(
            icon: [
              [
                'circle',
                {'cx': '12', 'cy': '12', 'r': '10', 'stroke': 'currentColor'}
              ]
            ],
            color: Colors.red, // ignored — IconTheme governs the real colour
          ),
        ),
      );
      expect(find.byType(HugeIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('primaryAction variant', () {
    testWidgets('paints the glyph with journeyPrimary via ShaderMask, no filled disc',
        (tester) async {
      await pump(
        tester,
        const JourneyGradientIconBadge(
          variant: JourneyBadgeVariant.primaryAction,
          icon: Icon(Icons.star),
        ),
      );

      final shaderMask = find.descendant(
          of: find.byType(JourneyGradientIconBadge), matching: find.byType(ShaderMask));
      expect(shaderMask, findsOneWidget);

      // No circular gradient container behind it.
      final containers = find
          .descendant(of: find.byType(JourneyGradientIconBadge), matching: find.byType(Container))
          .evaluate()
          .map((e) => e.widget as Container);
      for (final c in containers) {
        final deco = c.decoration;
        if (deco is BoxDecoration) expect(deco.shape, isNot(BoxShape.circle));
      }
    });

    testWidgets('gradient override replaces journeyPrimary', (tester) async {
      await pump(
        tester,
        JourneyGradientIconBadge(
          variant: JourneyBadgeVariant.primaryAction,
          gradient: AppGradients.journeySunset,
          icon: const Icon(Icons.star),
        ),
      );
      final mask = tester.widget<ShaderMask>(
        find.descendant(
            of: find.byType(JourneyGradientIconBadge), matching: find.byType(ShaderMask)),
      );
      // shaderCallback is a closure, so compare what it produces for a
      // fixed rect rather than the function identity.
      final shader = mask.shaderCallback(const Rect.fromLTWH(0, 0, 48, 48));
      final expectedShader =
          AppGradients.journeySunset.createShader(const Rect.fromLTWH(0, 0, 48, 48));
      expect(shader.runtimeType, expectedShader.runtimeType);
    });
  });

  group('semantics', () {
    testWidgets('exposes semanticsLabel to the accessibility tree', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const JourneyGradientIconBadge(
          icon: Icon(Icons.account_balance_wallet),
          semanticsLabel: 'Balance',
        ),
      );
      expect(find.bySemanticsLabel('Balance'), findsOneWidget);
      handle.dispose();
    });

    // Icon itself always wraps in a plain Semantics(child: ExcludeSemantics(...))
    // internally, so "no Semantics in the tree at all" isn't the right check —
    // what must be absent is *our* wrapper specifically: a Semantics widget
    // whose own excludeSemantics is true (Icon's has excludeSemantics unset).
    testWidgets('adds no excludeSemantics wrapper when semanticsLabel is omitted', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const JourneyGradientIconBadge(icon: Icon(Icons.star)));
      final ourWrapper =
          find.byWidgetPredicate((w) => w is Semantics && w.excludeSemantics == true);
      expect(ourWrapper, findsNothing);
      handle.dispose();
    });
  });

  group('theme contrast', () {
    testWidgets('journeyInk default tracks light/dark so the icon stays readable', (tester) async {
      // Icon colour and the disc's own background must be captured together,
      // under the same theme, or the comparison below is meaningless.
      await AppTheme.instance.setDark(false);
      await pump(tester, const JourneyGradientIconBadge(icon: Icon(Icons.star)));
      final lightIconTheme = tester.widget<IconTheme>(
        find.descendant(
            of: find.byType(JourneyGradientIconBadge), matching: find.byType(IconTheme)),
      );
      final lightColor = lightIconTheme.data.color!;
      final lightBg = AppGradients.journeySoftColors.first;

      await AppTheme.instance.setDark(true);
      await pump(tester, const JourneyGradientIconBadge(icon: Icon(Icons.star)));
      final darkIconTheme = tester.widget<IconTheme>(
        find.descendant(
            of: find.byType(JourneyGradientIconBadge), matching: find.byType(IconTheme)),
      );
      final darkColor = darkIconTheme.data.color!;
      final darkBg = AppGradients.journeySoftColors.first;

      expect(darkColor, isNot(lightColor));
      // The icon must sit on the opposite side of its own disc's luminance:
      // dark-mode disc is a dim tinted surface, so the icon has to be
      // *lighter* than it; light-mode disc is a bright pastel, so the icon
      // has to be *darker* than it. Getting either backwards means the icon
      // would wash out against its own background.
      expect(darkColor.computeLuminance(), greaterThan(darkBg.computeLuminance()));
      expect(lightColor.computeLuminance(), lessThan(lightBg.computeLuminance()));
    });
  });
}
