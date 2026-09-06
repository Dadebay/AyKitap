import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/models/book_suggestion.dart';
import 'package:aykitap/modules/profile/widgets/book_suggestion_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('completed book request is not displayed as pending',
      (tester) async {
    await AppLocale.instance.setLanguage(AppLanguageCode.en);
    addTearDown(() => AppLocale.instance.setLanguage(AppLanguageCode.tk));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSuggestionCard(
            suggestion: BookSuggestion(
              id: 12,
              name: 'Mai ve siyah',
              author: 'bilemok',
              language: 'tr',
              status: 'completed',
              createdAt: DateTime(2026, 9, 6),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
  });
}
