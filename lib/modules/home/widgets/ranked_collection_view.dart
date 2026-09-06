import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/library_book.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icon_circle_button.dart';
import 'ranked_collection_banner.dart';
import 'ranked_list_tile.dart';
import 'stagger_fade_in.dart';

/// The ranked variant of `CatalogCollectionBooksScreen` — a numbered list
/// over a cover-image banner, matching `CatalogRankShelfCard`'s "Daha
/// fazla" continuation instead of the plain grid the other (non-ranked)
/// collection cards use.
class RankedCollectionView extends StatelessWidget {
  final String title;
  final List<LibraryBook> books;

  /// The collection's own banner, as [CatalogRankShelfCard] resolved it —
  /// falls back to the top book's cover here too, only when the caller
  /// didn't have one either (e.g. reached some other way than that card's
  /// "Daha fazla").
  final String? bannerImage;

  const RankedCollectionView(
      {super.key, required this.title, required this.books, this.bannerImage});

  @override
  Widget build(BuildContext context) {
    final resolvedBanner = (bannerImage != null && bannerImage!.isNotEmpty)
        ? bannerImage
        : (books.isNotEmpty ? books.first.image : null);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bg,
            scrolledUnderElevation: 0,
            expandedHeight: 220,
            pinned: true,
            // `Center` un-tightens the constraints `NavigationToolbar` hands
            // the leading slot (it forces its own width/height on a bare
            // child) — without it the 38px button was stretched to fill
            // that box instead of staying its own size.
            leading: Center(
              child: IconCircleButton(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                onTap: () => Navigator.pop(context),
                size: 38,
                iconSize: 18,
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                iconColor: Colors.white,
              ),
            ),
            // Set directly on the SliverAppBar (not FlexibleSpaceBar.title)
            // so it stays put in the toolbar's normal spot instead of
            // hanging off the bottom edge of the banner while expanded.
            centerTitle: true,
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
                background: RankedCollectionBanner(imageUrl: resolvedBanner)),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            sliver: SliverList.builder(
              itemCount: books.length,
              itemBuilder: (context, i) => StaggerFadeIn(
                index: i,
                child: RankedListTile(rank: i + 1, book: books[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
