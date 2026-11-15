import 'dart:convert';

import 'package:aykitap/core/widgets/profile_avatar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('custom avatar reuses bytes and decodes at display size', (tester) async {
    final image = await rootBundle.load('assets/images/shelf_wood.webp');
    final photo = base64Encode(image.buffer.asUint8List());

    Widget app(String? source) => MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 2),
            child: Scaffold(
              body: ProfileAvatar(index: -1, size: 60, imageBase64: source),
            ),
          ),
        );

    await tester.pumpWidget(app(photo));
    final first = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    expect(first.width, 240);
    expect(first.height, isNull);

    await tester.pumpWidget(app(photo));
    final second = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    expect(second.imageProvider, first.imageProvider);

    await tester.pumpWidget(app(null));
    expect(find.byType(Image), findsNothing);
  });
}
