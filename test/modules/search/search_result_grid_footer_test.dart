import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/modules/search/widgets/search_result_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an optional action after non-empty book results',
      (tester) async {
    const footerKey = ValueKey('suggest-footer');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SearchResultGrid(
            books: [LibraryBook(id: 1, name: 'Alchemist')],
            padding: EdgeInsets.fromLTRB(20, 8, 20, 120),
            loadingMore: false,
            footer: Text('Suggest a book', key: footerKey),
          ),
        ),
      ),
    );

    expect(find.text('Alchemist'), findsOneWidget);
    expect(find.byKey(footerKey), findsOneWidget);
  });
}
