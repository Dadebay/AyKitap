import 'package:aykitap/core/models/collection.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/navigation/app_hero_tags.dart';
import 'package:aykitap/modules/book_detail/widgets/catalog_detail_header_art.dart';
import 'package:aykitap/modules/home/widgets/catalog_book_card.dart';
import 'package:aykitap/modules/home/widgets/catalog_numbered_book_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Card 4 and detail loading cover share one Hero tag',
      (tester) async {
    const book = LibraryBook(
      id: 42,
      name: 'Atomic Habits',
      authors: [LibraryBookAuthor(id: 7, name: 'James Clear')],
    );
    const collection = Collection(
      id: 11,
      type: CollectionType.book,
      cardType: CollectionCardType.card4,
      name: 'Bestsellers',
      books: [book],
    );
    final tag = AppHeroTags.homeCollectionBookCover(
      collection.id,
      book.id,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CatalogNumberedBookSection(collection: collection),
        ),
      ),
    );

    final sourceHero = tester.widget<Hero>(find.byType(Hero));
    expect(sourceHero.tag, tag);
    final coverLeft = tester.getTopLeft(find.byType(Hero)).dx;
    final titleLeft = tester.getTopLeft(find.text(book.name)).dx;
    expect(
      titleLeft,
      moreOrLessEquals(coverLeft, epsilon: 0.01),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogDetailHeaderArt(
            imageUrl: null,
            heroTag: tag,
          ),
        ),
      ),
    );

    final destinationHero = tester.widget<Hero>(find.byType(Hero));
    expect(destinationHero.tag, sourceHero.tag);
  });

  testWidgets('regular Home book exposes its supplied Hero tag',
      (tester) async {
    const book = LibraryBook(
      id: 9,
      name: 'Oýunbaz',
      authors: [LibraryBookAuthor(id: 3, name: 'Näbelli')],
    );
    const tag = 'home-collection-5-book-cover-9';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CatalogBookCard(
            book: book,
            heroTag: tag,
          ),
        ),
      ),
    );

    expect(tester.widget<Hero>(find.byType(Hero)).tag, tag);
  });

  test('same book in different collections receives different Hero tags', () {
    expect(
      AppHeroTags.homeCollectionBookCover(1, 42),
      isNot(AppHeroTags.homeCollectionBookCover(2, 42)),
    );
  });

  test('Hero rect travels directly between source and centered destination',
      () {
    final tween = AppHeroTags.straightRectTween(
      const Rect.fromLTWH(20, 400, 100, 155),
      const Rect.fromLTWH(119, 90, 152, 224),
    );

    expect(
      tween.lerp(0.5),
      const Rect.fromLTRB(69.5, 245, 195.5, 434.5),
    );
  });
}
