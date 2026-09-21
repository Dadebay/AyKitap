import 'package:aykitap/modules/reader/widgets/cbz_settings_sheet.dart';
import 'package:aykitap/modules/reader/widgets/pdf_settings_sheet.dart';
import 'package:aykitap/modules/reader/widgets/reader_landscape_row.dart';
import 'package:aykitap/modules/reader/utils/reader_orientation.dart';
import 'package:aykitap/modules/profile/widgets/settings_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The "ýatyk okamak" setting end to end below the widget layer: what it
/// stores, and what it actually asks the platform for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> requested;

  setUp(() {
    requested = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        requested = (call.arguments as List).cast<String>();
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('turning it on stores the choice and turns the phone immediately',
      () async {
    SharedPreferences.setMockInitialValues({});

    await setReaderLandscapeReading(true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(readerLandscapePrefKey), isTrue);
    // Changed from inside an open reader, so it has to take effect on the
    // book that is still on screen — not at the next one.
    expect(requested, isNot(contains('DeviceOrientation.portraitUp')));
    expect(requested, contains('DeviceOrientation.landscapeLeft'));
  });

  test('turning it off lets the phone go back to portrait', () async {
    SharedPreferences.setMockInitialValues({readerLandscapePrefKey: true});
    await setReaderLandscapeReading(true);

    await setReaderLandscapeReading(false);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(readerLandscapePrefKey), isFalse);
    expect(requested, contains('DeviceOrientation.portraitUp'));
  });

  test('the saved choice applies to every reader, not just the one that set it',
      () async {
    // PDF and CBZ have no settings row of their own, but call the same
    // enableReaderLandscape on open — so a book opened after the switch was
    // flipped in the EPUB reader still opens sideways.
    SharedPreferences.setMockInitialValues({readerLandscapePrefKey: true});

    await enableReaderLandscape();

    expect(requested, isNot(contains('DeviceOrientation.portraitUp')));
  });

  // Every reader's settings sheet offers it, not just the EPUB one: the
  // setting governs whichever book is open, so a reader in a PDF or a comic
  // must not have to go and open an EPUB to find the switch.
  group('the switch is reachable from every reader', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pumpSheet(WidgetTester tester, Widget sheet) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: sheet)));

    testWidgets('PDF settings sheet', (tester) async {
      await pumpSheet(
        tester,
        PdfSettingsSheet(
          colorMode: PdfColorMode.light,
          brightness: 1,
          eyeCare: 0,
          fitPolicy: PdfFitMode.width,
          viewMode: PdfViewMode.scroll,
          marginCrop: 0,
          onColorModeChanged: (_) {},
          onBrightnessChanged: (_) {},
          onEyeCareChanged: (_) {},
          onMarginCropChanged: (_) {},
          onFitChanged: (_) {},
          onViewModeChanged: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReaderLandscapeRow), findsOneWidget);
    });

    testWidgets('CBZ settings sheet', (tester) async {
      await pumpSheet(
        tester,
        CbzSettingsSheet(
          darkGutter: false,
          brightness: 1,
          eyeCare: 0,
          fit: BoxFit.contain,
          viewMode: CbzViewMode.scroll,
          onGutterChanged: (_) {},
          onBrightnessChanged: (_) {},
          onEyeCareChanged: (_) {},
          onFitChanged: (_) {},
          onViewModeChanged: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReaderLandscapeRow), findsOneWidget);
    });

    testWidgets('the row shows the stored value and writes back to it',
        (tester) async {
      SharedPreferences.setMockInitialValues({readerLandscapePrefKey: true});
      await pumpSheet(tester, const ReaderLandscapeRow());
      await tester.pumpAndSettle();

      // Reads what a previous reader (any of the three) stored...
      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      // ...and writing goes back to the same one place.
      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(readerLandscapePrefKey), isFalse);
    });
  });
}
