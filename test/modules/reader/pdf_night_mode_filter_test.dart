// Night mode inverts everything drawn inside it, the viewer's own gutter
// included — so the gutter has to be handed the opposite of what it should
// look like. Reported as: theme set to "Gije", but in paged mode the page sat
// in a bright white surround.
import 'package:aykitap/modules/reader/widgets/pdf_night_mode_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The night-mode gutter colour the PDF reader asks for.
const _nightGutter = Color(0xFF1C1C1E);

/// What [PdfNightModeFilter]'s own matrix does to a colour, so the tests
/// check the round trip against the real transform rather than against a
/// restatement of `preInverted`.
Color _asTheFilterWouldPaint(Color c) => Color.from(
      alpha: c.a,
      red: 1 - c.r,
      green: 1 - c.g,
      blue: 1 - c.b,
    );

void main() {
  test('the night gutter survives the filter as the colour asked for', () {
    final onScreen =
        _asTheFilterWouldPaint(PdfNightModeFilter.preInverted(_nightGutter));

    expect(onScreen.r, closeTo(_nightGutter.r, 0.001));
    expect(onScreen.g, closeTo(_nightGutter.g, 0.001));
    expect(onScreen.b, closeTo(_nightGutter.b, 0.001));
  });

  test('handing the filter the colour directly is what turned it white', () {
    // The bug: the near-black gutter reached the screen as a near-white.
    final onScreen = _asTheFilterWouldPaint(_nightGutter);

    expect(onScreen.r, greaterThan(0.8));
    expect(onScreen.g, greaterThan(0.8));
    expect(onScreen.b, greaterThan(0.8));
  });

  test('pre-inverting a near-black gives a near-white to paint', () {
    final toPaint = PdfNightModeFilter.preInverted(_nightGutter);

    expect(toPaint.r, greaterThan(0.8));
  });

  test('alpha is left alone, matching the filter matrix', () {
    const translucent = Color(0x801C1C1E);

    expect(PdfNightModeFilter.preInverted(translucent).a,
        closeTo(translucent.a, 0.001));
  });

  test('inverting twice returns the original colour', () {
    final twice = PdfNightModeFilter.preInverted(PdfNightModeFilter.preInverted(
      _nightGutter,
    ));

    expect(twice.r, closeTo(_nightGutter.r, 0.001));
    expect(twice.b, closeTo(_nightGutter.b, 0.001));
  });

  group('what the gutter and the page end up as', () {
    /// A PDF's white paper, as night mode leaves it.
    final invertedPaper = _asTheFilterWouldPaint(Colors.white);

    test('an inverted white page is pure black', () {
      expect(invertedPaper.r, closeTo(0, 0.001));
      expect(invertedPaper.g, closeTo(0, 0.001));
      expect(invertedPaper.b, closeTo(0, 0.001));
    });

    test('the gutter lands on exactly that, so the page does not float', () {
      // What the page layer hands pdfrx as its background in night mode.
      final gutter =
          _asTheFilterWouldPaint(PdfNightModeFilter.preInverted(Colors.black));

      expect(gutter.r, closeTo(invertedPaper.r, 0.001));
      expect(gutter.g, closeTo(invertedPaper.g, 0.001));
      expect(gutter.b, closeTo(invertedPaper.b, 0.001));
    });

    test('the theme surface would not have matched it', () {
      // [bg] for night mode — right for the chrome outside the filter, but
      // visibly lighter than the page it would have surrounded.
      final surface =
          _asTheFilterWouldPaint(PdfNightModeFilter.preInverted(_nightGutter));

      expect(surface.r, greaterThan(invertedPaper.r + 0.05));
    });
  });

  test('pdfrx\'s default page shadow would render as a white glow', () {
    // Why night mode drops the shadow instead of keeping it: black54 is a
    // shadow on a light gutter and a halo on a dark one.
    final glow = _asTheFilterWouldPaint(Colors.black54);

    expect(glow.r, closeTo(1, 0.001));
    expect(glow.a, closeTo(Colors.black54.a, 0.001));
  });

  testWidgets('the filter only wraps its child when enabled', (tester) async {
    await tester.pumpWidget(const PdfNightModeFilter(
        enabled: false, child: SizedBox(key: Key('page'))));
    expect(find.byType(ColorFiltered), findsNothing);

    await tester.pumpWidget(const PdfNightModeFilter(
        enabled: true, child: SizedBox(key: Key('page'))));
    expect(find.byType(ColorFiltered), findsOneWidget);
  });
}
