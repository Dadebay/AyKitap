import 'package:aykitap/modules/search/widgets/search_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the 3D connection artwork and retries', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchErrorState(
            message: 'Could not connect to the internet.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('search-error-3d-image')), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('search-error-3d-image')),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/no_connection_dark_transparent.png',
    );
    expect(find.text('Could not connect to the internet.'), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
}
