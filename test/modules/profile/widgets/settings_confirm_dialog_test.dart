import 'package:aykitap/modules/profile/widgets/settings_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confirm closes only the dialog and returns true',
      (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('Settings page'),
                ElevatedButton(
                  onPressed: () async {
                    result = await showSettingsConfirmDialog(
                      context,
                      icon: const Icon(Icons.logout),
                      iconSize: 48,
                      iconColor: Colors.orange,
                      title: 'Log out?',
                      body: 'Confirm logout',
                      confirmLabel: 'Confirm',
                      confirmColor: Colors.orange,
                    );
                  },
                  child: const Text('Open dialog'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Log out?'), findsNothing);
    expect(find.text('Settings page'), findsOneWidget);
  });
}
