import 'package:aykitap/core/services/device_tier.dart';
import 'package:aykitap/modules/reader/widgets/book_opening_overlay.dart';
import 'package:aykitap/modules/reader/widgets/reader_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await DeviceTier.init();
    // Widget tests require the scheduler clock to stay at its default rate.
    timeDilation = 1.0;
  });

  testWidgets('EPUB opening shows Lottie', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BookOpeningOverlay(
          bgColor: Colors.black,
          loaded: false,
          onDone: () {},
        ),
      ),
    ));

    expect(find.byType(Lottie), findsOneWidget);
  });

  testWidgets('PDF and CBZ loading shows Lottie', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ReaderLoadingOverlay(
              backgroundColor: Colors.black,
              isDarkSurface: true,
              message: 'Opening book',
            ),
          ],
        ),
      ),
    ));

    expect(find.byType(Lottie), findsOneWidget);
  });
}
