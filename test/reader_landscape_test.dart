import 'package:aykitap/modules/reader/widgets/cbz_settings_sheet.dart';
import 'package:aykitap/modules/reader/widgets/pdf_bottom_bar.dart';
import 'package:aykitap/modules/reader/widgets/pdf_settings_sheet.dart';
import 'package:aykitap/modules/reader/widgets/reader_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_test/flutter_test.dart';

/// The readers can be rotated (see reader_orientation.dart), which leaves their
/// sheets roughly 380dp tall instead of ~750dp. These pump each sheet at that
/// height and fail on any RenderFlex overflow — the "BOTTOM OVERFLOWED BY x
/// PIXELS" stripe — so a sheet that only fits in portrait can't ship.
const Size _landscape = Size(844, 390); // iPhone-class phone on its side

Future<void> _pumpSheet(WidgetTester tester, Widget sheet) async {
  tester.view.physicalSize = _landscape;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Sheets are shown via showModalBottomSheet(isScrollControlled: true),
        // which lays them out bottom-aligned against the full viewport.
        body: Align(alignment: Alignment.bottomCenter, child: sheet),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('PDF settings sheet fits a landscape viewport', (tester) async {
    await _pumpSheet(
      tester,
      PdfSettingsSheet(
        colorMode: PdfColorMode.light,
        brightness: 0.5,
        eyeCare: 0.0,
        fitPolicy: FitPolicy.BOTH,
        viewMode: PdfViewMode.paged,
        onColorModeChanged: (_) {},
        onBrightnessChanged: (_) {},
        onEyeCareChanged: (_) {},
        onFitChanged: (_) {},
        onViewModeChanged: (_) {},
        onSwitchToTextView: () {},
      ),
    );
    expect(tester.takeException(), isNull);
  });

  // The bars are always on screen, so they must not overflow *and* must give
  // height back to the page once rotated — the whole point of the compact
  // variant. 132 + padding is the portrait height they shrink from.
  testWidgets('EPUB bottom bar is compact in landscape', (tester) async {
    await _pumpSheet(
      tester,
      ReaderBottomBar(
        progress: 0.5,
        currentPage: 5,
        totalPages: 100,
        pageColor: Colors.white,
        onSettings: () {},
        onChapters: () {},
        onSearch: () {},
        onProgressChanged: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ReaderBottomBar)).height, lessThan(132));
  });

  testWidgets('PDF bottom bar is compact in landscape', (tester) async {
    await _pumpSheet(
      tester,
      PdfBottomBar(
        progress: 0.5,
        currentPage: 5,
        totalPages: 100,
        pageColor: Colors.white,
        onSettings: () {},
        onBookmarks: () {},
        onGoToPage: () {},
        onProgressChanged: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PdfBottomBar)).height, lessThan(132));
  });

  // Guards the other direction: the compaction is landscape-only, so portrait
  // must keep its full-height bar with the captions showing.
  testWidgets('EPUB bottom bar keeps captions in portrait', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ReaderBottomBar(
              progress: 0.5,
              currentPage: 5,
              totalPages: 100,
              pageColor: Colors.white,
              onSettings: () {},
              onChapters: () {},
              onSearch: () {},
              onProgressChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ReaderBottomBar)).height, 132);
  });

  testWidgets('CBZ settings sheet fits a landscape viewport', (tester) async {
    await _pumpSheet(
      tester,
      CbzSettingsSheet(
        darkGutter: true,
        brightness: 0.5,
        eyeCare: 0.0,
        fit: BoxFit.contain,
        // Paged shows the extra page-scale section, so this is the tallest the
        // sheet ever gets — the case most likely to overflow.
        viewMode: CbzViewMode.paged,
        onGutterChanged: (_) {},
        onBrightnessChanged: (_) {},
        onEyeCareChanged: (_) {},
        onFitChanged: (_) {},
        onViewModeChanged: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
