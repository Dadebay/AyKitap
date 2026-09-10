// Regression coverage for the reported "New York Times iň köp satylanlary"
// card: the banner title was laid out with only a `left` inset and no `right`,
// so a long collection name ran past the card and was cut off by the banner's
// ClipRRect instead of wrapping.
import 'package:aykitap/core/models/collection.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/modules/home/widgets/catalog_rank_shelf_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longTitle = 'New York Times iň köp satylanlary';

Collection _collection({String name = _longTitle, String? subTitle}) =>
    Collection(
      id: 1,
      type: CollectionType.book,
      cardType: CollectionCardType.card2,
      name: name,
      subTitle: subTitle,
      books: const [
        LibraryBook(
          id: 10,
          name: 'Atomic habits',
          authors: [LibraryBookAuthor(id: 1, name: 'Jeýms Klir')],
        ),
      ],
    );

void main() {
  // 320 is the width the genre-shelf row gives this card — the tightest real
  // placement, and the one in the screenshot.
  Widget wrap(Collection collection) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CatalogRankShelfCard(collection: collection),
            ),
          ),
        ),
      );

  testWidgets('a long collection name wraps to two lines instead of being cut',
      (tester) async {
    await tester.pumpWidget(wrap(_collection()));
    await tester.pump();

    final title = tester.widget<Text>(find.text(_longTitle));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets('the title stays inside the card rather than running past it',
      (tester) async {
    await tester.pumpWidget(wrap(_collection()));
    await tester.pump();

    final card = tester.getRect(find.byType(CatalogRankShelfCard));
    final title = tester.getRect(find.text(_longTitle));

    // The bug: unbounded on the right, the title's own box extended beyond
    // the card and only *looked* trimmed because the banner clipped it.
    expect(title.right, lessThanOrEqualTo(card.right));
    expect(title.left, greaterThanOrEqualTo(card.left));
  });

  testWidgets('a two-line title and a subtitle both fit the 84px banner',
      (tester) async {
    await tester
        .pumpWidget(wrap(_collection(subTitle: 'Hepdelik täzelenýän sanaw')));
    await tester.pump();

    // A RenderFlex overflow inside the banner would already have failed this
    // pump; these confirm both lines are actually laid out, not dropped.
    expect(find.text(_longTitle), findsOneWidget);
    expect(find.text('Hepdelik täzelenýän sanaw'), findsOneWidget);

    final title = tester.getRect(find.text(_longTitle));
    // Two lines at 18px with height 1.15 — comfortably over one line's worth.
    expect(title.height, greaterThan(30));
  });

  testWidgets('a short name still renders on a single line', (tester) async {
    await tester.pumpWidget(wrap(_collection(name: 'Täzeler')));
    await tester.pump();

    final title = tester.getRect(find.text('Täzeler'));
    expect(title.height, lessThan(30));
  });
}
