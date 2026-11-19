import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/modules/reader/utils/google_translate_launcher.dart';
import 'package:aykitap/modules/reader/widgets/selection_toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as flutter_material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('web fallback keeps the full sentence and target language', () {
    const sentence = 'Aýkitap: read & learn?';
    final uri = GoogleTranslateLauncher.urlFor(sentence, AppLanguageCode.tk);
    expect(uri.scheme, 'https');
    expect(uri.host, 'translate.google.com');
    expect(uri.queryParameters['text'], sentence);
    expect(uri.queryParameters['sl'], 'auto');
    expect(uri.queryParameters['tl'], 'tk');
  });

  test('Android sends selected text directly to the Translate app', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('com.aykitap.aykitap/translate');
    String? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'openSelectedText');
      sent = call.arguments as String;
      return true;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    expect(await GoogleTranslateLauncher.open('  A whole sentence.  '), isTrue);
    expect(sent, 'A whole sentence.');
  });

  test('Android opens the translation link in Chrome if Translate is absent',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('com.aykitap.aykitap/translate');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'openSelectedText') return false;
      final url = Uri.parse(call.arguments as String);
      expect(url.host, 'translate.google.com');
      expect(url.queryParameters['text'], 'A whole sentence.');
      return true;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    expect(await GoogleTranslateLauncher.open('A whole sentence.'), isTrue);
    expect(calls, ['openSelectedText', 'openInChrome']);
  });

  testWidgets('selection toolbar exposes the Dict action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(flutter_material.MaterialApp(
      home: flutter_material.Scaffold(
        body: flutter_material.Stack(children: [
          SelectionToolbar(
            selectedText: 'A whole sentence.',
            selectionRect: null,
            canAnnotate: true,
            onAddNote: () {},
            onRemoveHighlight: () {},
            onCopy: () {},
            onShare: () {},
            onDict: () => tapped = true,
            onClose: () {},
          ),
        ]),
      ),
    ));

    await tester.tap(find.text('Dict'));
    expect(tapped, isTrue);
  });
}
