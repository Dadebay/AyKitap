import 'package:flutter/material.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_hero_tags.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import 'widgets/catalog_book_card.dart';
import 'widgets/ranked_collection_view.dart';
import 'widgets/stagger_fade_in.dart';

/// "Ählisini gör" / "see more" destination for one real [Collection]'s full
/// book list — the real-catalogue counterpart to `CollectionBooksScreen`
/// (mock `Book`), reusing the same [CatalogBookCard] every other real-book
/// list in the app uses (Home's rows, [CatalogAuthorDetailScreen]) rather
/// than a one-off card design just for this grid.
///
/// [ranked] switches to [RankedCollectionView] — see its own doc comment.
class CatalogCollectionBooksScreen extends StatelessWidget {
  /// Shared by the grid delegate and the entrance stagger, so the two can't
  /// drift out of sync and start cascading against the real row layout.
  static const _crossAxisCount = 3;

  final String title;
  final List<LibraryBook> books;

  /// Set from [CatalogRankShelfCard]'s "Daha fazla" — that card already
  /// leads with a numbered top-4 list over a cover-image banner, so its
  /// "see more" continues that same ranked-list shape instead of switching
  /// to the plain grid the other (non-ranked) collection cards use.
  final bool ranked;

  const CatalogCollectionBooksScreen(
      {super.key,
      required this.title,
      required this.books,
      this.ranked = false});

  @override
  Widget build(BuildContext context) {
    if (ranked) return RankedCollectionView(title: title, books: books);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(title,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: books.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.5,
          ),
          // Staggered by *row* (`i ~/ _crossAxisCount`), not by raw index:
          // the three cards sharing a row read as one unit, so cascading
          // them individually looks like a stutter rather than an
          // entrance. [StaggerFadeIn] clamps the delay it derives from
          // this, so a long collection still finishes entering promptly
          // instead of trickling in for the length of the list.
          itemBuilder: (context, i) => StaggerFadeIn(
            index: i ~/ _crossAxisCount,
            child: CatalogBookCard(
                book: books[i],
                heroTag: AppHeroTags.catalogBookCover(books[i].id),
                width: double.infinity,
                coverHeight: 170,
                margin: EdgeInsets.zero),
          ),
        ),
      ),
    );
  }
}
