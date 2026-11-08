import 'dart:async';

import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/services/book_access_service.dart';
import 'package:aykitap/core/services/subscription_service.dart';
import 'package:aykitap/modules/library/widgets/api_books_tab.dart';
import 'package:aykitap/modules/library/widgets/library_book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('locally opened book appears while backend fetch is pending',
      (tester) async {
    final localChanges = ChangeNotifier();
    final backendResult = Completer<List<LibraryBook>>();
    var localBooks = <LibraryBook>[];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookAccessService>.value(
              value: BookAccessService.instance),
          ChangeNotifierProvider<SubscriptionService>.value(
              value: SubscriptionService.instance),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ApiBooksTab(
              fetcher: () => backendResult.future,
              offlineFetcher: () async => localBooks,
              offlineRefreshOn: localChanges,
              emptyLabel: 'No books',
              heroShelf: 'reading',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(LibraryBookCover), findsNothing);

    localBooks = const [
      LibraryBook(id: 478, name: 'The art of spending money'),
    ];
    localChanges.notifyListeners();
    await tester.pump();

    final cover = tester.widget<LibraryBookCover>(
      find.byType(LibraryBookCover),
    );
    expect(cover.book.id, 478);

    await tester.pumpWidget(const SizedBox.shrink());
    localChanges.dispose();
  });
}
