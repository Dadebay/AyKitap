import 'package:aykitap/modules/reader/widgets/reader_progress_scrubber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const totalPages = 383;

  Widget scrubberAt(int page) => MaterialApp(
        home: Scaffold(
          body: ReaderProgressScrubber(
            progress: (page - 1) / (totalPages - 1),
            currentPage: page,
            totalPages: totalPages,
            labelColor: Colors.white,
            activeColor: Colors.white,
            inactiveTrackColor: Colors.grey,
            overlayColor: Colors.white24,
            onSeek: (_) {},
          ),
        ),
      );

  group('page label switching', () {
    // The label's AnimatedSwitcher keeps an outgoing child mounted for its
    // full 180ms fade. Scrolling a PDF re-crosses a page boundary well inside
    // that window, so a page number can come back while its own previous
    // label is still fading — which, when the switcher's children were keyed
    // by the page number itself, put two identically-keyed children in its
    // Stack and threw "Duplicate keys found".
    testWidgets('a page returning mid-fade does not throw on duplicate keys',
        (tester) async {
      await tester.pumpWidget(scrubberAt(20));

      // Each step lands well inside the previous label's fade.
      for (final page in [21, 20, 21, 22, 21]) {
        await tester.pumpWidget(scrubberAt(page));
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull,
            reason: 'moving to page $page threw');
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('21'), findsOneWidget);
    });

    testWidgets('the label follows the current page', (tester) async {
      await tester.pumpWidget(scrubberAt(19));
      await tester.pumpAndSettle();
      expect(find.text('19'), findsOneWidget);

      await tester.pumpWidget(scrubberAt(20));
      await tester.pumpAndSettle();
      expect(find.text('20'), findsOneWidget);
      expect(find.text('19'), findsNothing);
    });

    testWidgets('rebuilding on an unchanged page does not restart the fade',
        (tester) async {
      await tester.pumpWidget(scrubberAt(42));
      await tester.pumpAndSettle();

      // A rebuild carrying the same page must keep the same switcher key, or
      // the number would visibly re-fade every time the reader's progress
      // ticks without the page actually turning.
      await tester.pumpWidget(scrubberAt(42));
      await tester.pump(const Duration(milliseconds: 40));

      expect(tester.takeException(), isNull);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('the total page count is shown alongside', (tester) async {
      await tester.pumpWidget(scrubberAt(19));
      await tester.pumpAndSettle();
      expect(find.text('$totalPages'), findsOneWidget);
    });
  });
}
