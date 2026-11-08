// Regression coverage for S6 (see .Codex/SONNET_TRANSLATION_THEME_TASKS.md):
// [CatalogAuthorCard] must fall back to a monogram (never a broken image)
// when there's no photo, truncate long names instead of overflowing, and
// show a book-count badge only when the caller actually has a count.
import 'package:aykitap/core/localization/strings/author_strings.dart';
import 'package:aykitap/modules/home/widgets/catalog_author_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
      'shows initials monogram, not a broken image, when there is no photo',
      (tester) async {
    await tester.pumpWidget(wrap(const CatalogAuthorCard(
      authorId: 1,
      name: 'Gurbanguly Berdimuhamedow',
      width: 130,
    )));
    await tester.pump();

    expect(find.text('GB'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('truncates a long name to two lines instead of overflowing',
      (tester) async {
    const longName =
        'A Very Long Author Name That Would Otherwise Overflow The Card';
    await tester.pumpWidget(wrap(const CatalogAuthorCard(
      authorId: 2,
      name: longName,
      width: 130,
    )));
    await tester.pump();

    final text = tester.widget<Text>(find.text(longName));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    // No overflow exception was thrown by the pump above — that's the real
    // assertion; the maxLines/overflow checks above are what prevents it.
  });

  testWidgets(
      'shows the book count when given, and the generic Author badge otherwise',
      (tester) async {
    await tester.pumpWidget(wrap(const CatalogAuthorCard(
      authorId: 3,
      name: 'Author With Count',
      bookCount: 5,
      width: 130,
    )));
    await tester.pump();
    expect(find.text(AuthorStrings.booksCountLabel(5)), findsOneWidget);
    expect(find.text(AuthorStrings.authorLabel), findsNothing);

    await tester.pumpWidget(wrap(const CatalogAuthorCard(
      authorId: 4,
      name: 'Author Without Count',
      width: 130,
    )));
    await tester.pump();
    expect(find.text(AuthorStrings.authorLabel), findsOneWidget);
  });
}
