import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/navigation/app_hero_tags.dart';
import 'package:aykitap/core/services/book_access_service.dart';
import 'package:aykitap/core/services/subscription_service.dart';
import 'package:aykitap/modules/library/widgets/library_book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('the same book on two different shelves gets two different Hero tags',
      () {
    expect(
      AppHeroTags.libraryShelfBookCover('purchased', 42),
      isNot(AppHeroTags.libraryShelfBookCover('favorites', 42)),
    );
  });

  testWidgets(
      'the same book rendered on two kept-alive shelves at once does not throw a duplicate-Hero error',
      (tester) async {
    // Regression: LibraryScreen keeps every tab's ApiBooksTab/DownloadedTab
    // alive at once (AutomaticKeepAliveClientMixin), so a purchased book
    // that's also being read can have two LibraryBookCovers mounted on the
    // same route simultaneously. Before heroShelf existed both used the
    // plain per-id tag and Flutter throws "multiple heroes that share the
    // same tag" the moment two of them are in the tree together.
    const book = LibraryBook(id: 42, name: 'Atomic Habits', authors: []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookAccessService>.value(
              value: BookAccessService.instance),
          ChangeNotifierProvider<SubscriptionService>.value(
              value: SubscriptionService.instance),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 120,
                  child: LibraryBookCover(book: book, heroShelf: 'reading'),
                ),
                SizedBox(
                  width: 80,
                  height: 120,
                  child: LibraryBookCover(book: book, heroShelf: 'purchased'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final tags =
        tester.widgetList<Hero>(find.byType(Hero)).map((h) => h.tag).toSet();
    expect(tags, hasLength(2));
  });
}
