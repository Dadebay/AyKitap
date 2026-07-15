import 'package:flutter_test/flutter_test.dart';

import 'package:aykitap/main.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const AykitapApp());
    await tester.pump();
  });
}
