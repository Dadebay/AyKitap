// Card 4 was reported as "beter uly" — its covers came out nearly twice the
// size of the plain book row's on the same Home screen, so the ranked shelf
// read as a different screen rather than as a featured section.
import 'package:aykitap/core/models/collection.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/widgets/book_cover_hero.dart';
import 'package:aykitap/modules/home/widgets/catalog_book_card.dart';
import 'package:aykitap/modules/home/widgets/catalog_numbered_book_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [CatalogBookCard]'s defaults — the covers Card 4 sits beside on Home.
const _plainCoverWidth = 100.0;
const _plainCoverHeight = 155.0;

/// A typical phone, so the width actually comes from the screen fraction
/// rather than from the clamp at either end.
const _phone = Size(411, 900);

const _collection = Collection(
  id: 1,
  type: CollectionType.book,
  cardType: CollectionCardType.card4,
  name: 'Redaktoryň Saýlanlary',
  // Without one the header falls back to printing the book count, which a
  // one-book fixture renders as "1" — the same string as the rank numeral.
  subTitle: 'Toparymyz tarapyndan saýlananlar',
  books: [
    LibraryBook(
      id: 10,
      name: 'Alchemist',
      authors: [LibraryBookAuthor(id: 1, name: 'Paulo Koelo')],
    ),
  ],
);

Widget _wrap({Size size = _phone, bool compact = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: CatalogNumberedBookSection(
            collection: _collection,
            compact: compact,
          ),
        ),
      ),
    );

void main() {
  Future<Size> coverSize(WidgetTester tester, {Size size = _phone}) async {
    await tester.pumpWidget(_wrap(size: size));
    await tester.pump();
    return tester.getSize(find.byType(BookCoverHero));
  }

  testWidgets('a rank cover no longer dwarfs the plain book row beside it',
      (tester) async {
    final cover = await coverSize(tester);

    // It used to be ~179x269 against the row's 100x155 — 1.8x in both
    // directions. Now a shade over them rather than a multiple.
    expect(cover.width, lessThan(_plainCoverWidth * 1.25));
    expect(cover.height, lessThan(_plainCoverHeight * 1.25));
  });

  testWidgets('but stays the larger, featured treatment', (tester) async {
    final cover = await coverSize(tester);

    expect(cover.width, greaterThan(_plainCoverWidth));
    expect(cover.height, greaterThan(_plainCoverHeight));
  });

  testWidgets('a cover keeps its 2:3 proportions', (tester) async {
    final cover = await coverSize(tester);

    expect(cover.height / cover.width, closeTo(1.5, 0.01));
  });

  testWidgets('a narrow phone is held up by the lower clamp', (tester) async {
    // 320 * 0.42 = 134, under the 150 floor — the card must not collapse to
    // the point of losing the ranked look.
    final cover = await coverSize(tester, size: const Size(320, 640));

    expect(cover.width, greaterThan(_plainCoverWidth));
  });

  testWidgets('a tablet is held down by the upper clamp', (tester) async {
    final phoneCover = await coverSize(tester);
    final tabletCover = await coverSize(tester, size: const Size(900, 1200));

    expect(tabletCover.width, greaterThanOrEqualTo(phoneCover.width));
    expect(tabletCover.width, lessThan(_plainCoverWidth * 1.5));
  });

  testWidgets('the compact variant is untouched', (tester) async {
    // The genre-shelf row sizes this one itself; only the standalone Home
    // placement was the complaint.
    await tester.pumpWidget(_wrap(compact: true));
    await tester.pump();

    // 150 wide, cover is 0.78 of that.
    expect(tester.getSize(find.byType(BookCoverHero)).width,
        closeTo(150 * 0.78, 0.5));
  });

  testWidgets('the rank numeral still renders over the cover', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    // Two copies by design: the filled numeral behind the cover and the
    // outlined one clipped above it.
    expect(find.text('1'), findsNWidgets(2));
  });
}
