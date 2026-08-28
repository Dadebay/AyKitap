// Regression cover for the shelf -> detail shared-element flight.
//
// The flight used to show the *destination* widget for its whole duration:
// the cover left the shelf already wearing the detail page's 36px shadow and
// its corner radius, snapping on the first frame of the tap. It also let the
// artwork re-resolve its decode size from the Hero's per-frame constraints,
// which re-decoded the image on every frame of the flight.
import 'package:aykitap/core/navigation/app_navigator.dart';
import 'package:aykitap/core/navigation/hero_page_route.dart';
import 'package:aykitap/core/theme/app_motion.dart';
import 'package:aykitap/core/widgets/book_cover_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _cardStyle = BookCoverStyle(
  borderRadius: 6,
  shadows: [BoxShadow(color: Color(0x38000000), blurRadius: 10)],
);
const _detailStyle = BookCoverStyle(
  borderRadius: 8,
  shadows: [
    BoxShadow(color: Color(0x8C000000), blurRadius: 36, spreadRadius: 2),
    BoxShadow(color: Color(0x33000000), blurRadius: 10),
  ],
);
const _tag = 'catalog-book-cover-42';

/// The shuttle is the only place a [FittedBox] appears in these trees, so it
/// is what identifies the in-flight cover.
Finder get _flightArtwork => find.byType(FittedBox);

BoxDecoration _flightDecoration(WidgetTester tester) {
  final container =
      find.ancestor(of: _flightArtwork, matching: find.byType(Container)).first;
  return tester.widget<Container>(container).decoration! as BoxDecoration;
}

Widget _detailPage() => Scaffold(
      body: Center(
        child: BookCoverHero(
          tag: _tag,
          width: 152,
          height: 224,
          style: _detailStyle,
          child: const ColoredBox(color: Color(0xFF445566)),
        ),
      ),
    );

Widget _shelfApp() => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomLeft,
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => context.pushHero(_detailPage()),
              child: BookCoverHero(
                tag: _tag,
                width: 100,
                height: 155,
                style: _cardStyle,
                child: const ColoredBox(color: Color(0xFF445566)),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('flight interpolates the cover chrome instead of snapping to it',
      (tester) async {
    await tester.pumpWidget(_shelfApp());
    await tester.tap(find.byType(BookCoverHero));
    await tester.pump();

    // One frame in, the cover must still be wearing something close to the
    // shelf's chrome — this is the frame the old default shuttle got wrong.
    await tester.pump(const Duration(milliseconds: 16));
    final early = _flightDecoration(tester);
    final earlyRadius = (early.borderRadius! as BorderRadius).topLeft.x;
    expect(earlyRadius, lessThan(7));
    expect(early.boxShadow!.first.blurRadius, lessThan(20));

    // Halfway, strictly between the two ends in both radius and shadow.
    await tester.pump(const Duration(milliseconds: 134));
    final mid = _flightDecoration(tester);
    final midRadius = (mid.borderRadius! as BorderRadius).topLeft.x;
    expect(midRadius, greaterThan(6));
    expect(midRadius, lessThan(8));
    expect(mid.boxShadow!.first.blurRadius, greaterThan(10));
    expect(mid.boxShadow!.first.blurRadius, lessThan(36));

    await tester.pumpAndSettle();
    expect(_flightArtwork, findsNothing);
  });

  testWidgets('flight artwork keeps one decode size for the whole flight',
      (tester) async {
    await tester.pumpWidget(_shelfApp());
    await tester.tap(find.byType(BookCoverHero));
    await tester.pump();

    Size artworkSize() {
      final box = find
          .descendant(of: _flightArtwork, matching: find.byType(SizedBox))
          .first;
      final sized = tester.widget<SizedBox>(box);
      return Size(sized.width!, sized.height!);
    }

    await tester.pump(const Duration(milliseconds: 16));
    final first = artworkSize();
    await tester.pump(const Duration(milliseconds: 150));
    expect(artworkSize(), first);
    expect(first, const Size(152, 224));

    await tester.pumpAndSettle();
  });

  testWidgets('pushHero fades the page in rather than zooming it',
      (tester) async {
    await tester.pumpWidget(_shelfApp());
    await tester.tap(find.byType(BookCoverHero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final route = ModalRoute.of(
      tester.element(find.byType(Scaffold).last),
    );
    expect(route, isA<HeroPageRoute<dynamic>>());
    expect(route!.transitionDuration, AppMotion.heroFlight);

    // A partially faded destination, and no scale anywhere driving it — the
    // platform zoom transition is what the straight cover flight was fighting.
    final fade = tester.widgetList<FadeTransition>(find.byType(FadeTransition));
    expect(fade.any((f) => f.opacity.value > 0 && f.opacity.value < 1), isTrue);

    await tester.pumpAndSettle();
  });

  test('lerp pads a shorter shadow list so the extra shadow fades in', () {
    final quarter = BookCoverStyle.lerp(_cardStyle, _detailStyle, 0.25);
    expect(quarter.shadows.length, 2);
    // Second shadow only exists on the detail end, so at t=0.25 it is a
    // quarter of the way up from fully transparent.
    expect(quarter.shadows[1].blurRadius, closeTo(2.5, 0.01));
    expect(quarter.borderRadius, closeTo(6.5, 0.01));
  });
}
