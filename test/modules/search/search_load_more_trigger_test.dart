// Why the search grid stopped paging at the bottom until you scrolled up and
// came back — reported 21.09.2026 ("alta varinca yeni kitaplar eklenmiyor").
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/modules/search/widgets/search_result_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<LibraryBook> _books(int count) =>
    [for (var i = 0; i < count; i++) LibraryBook(id: i, name: 'Kitap $i')];

void main() {
  testWidgets(
      'appending a page fires no ScrollNotification, so a notification-driven '
      'trigger never re-checks', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var notifications = 0;
    var books = _books(30);
    late StateSetter rebuild;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            notifications++;
            return false;
          },
          child: StatefulBuilder(builder: (context, setState) {
            rebuild = setState;
            return SearchResultGrid(
              books: books,
              padding: EdgeInsets.zero,
              loadingMore: false,
              controller: controller,
            );
          }),
        ),
      ),
    ));

    // Park at the very bottom, the way a reader who scrolled to the end is.
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final extentBefore = controller.position.maxScrollExtent;
    notifications = 0;

    // The next page lands while nothing is being scrolled.
    rebuild(() => books = _books(60));
    await tester.pumpAndSettle();

    // The grid grew — but silently. This is the whole bug: a
    // NotificationListener-only trigger has nothing to react to here, so
    // paging stalled until the reader manually produced a scroll.
    expect(controller.position.maxScrollExtent, greaterThan(extentBefore));
    expect(notifications, 0);

    // ...which is why the trigger reads the controller after the frame
    // instead: from there the grown extent, and the distance left to the
    // bottom, are both visible without any scrolling having happened.
    final position = controller.position;
    expect(position.maxScrollExtent - position.pixels, greaterThan(0));
  });

  testWidgets('a first page too short to scroll can never trigger a scroll',
      (tester) async {
    // The other half of the same defect: with nothing to scroll there is no
    // notification at all, so a short first page stayed the only page.
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var notifications = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            notifications++;
            return false;
          },
          child: SearchResultGrid(
            books: _books(3),
            padding: EdgeInsets.zero,
            loadingMore: false,
            controller: controller,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(controller.position.maxScrollExtent, 0);
    expect(notifications, 0);
    // A controller read still answers "you are at the end" — which is what
    // lets the post-frame check fetch page 2 here.
    final position = controller.position;
    expect(position.maxScrollExtent - position.pixels, lessThan(600));
  });
}
