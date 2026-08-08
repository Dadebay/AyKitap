import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/network_cover_image.dart';
import '../../core/localization/strings/book_detail_strings.dart';
import '../book_detail/catalog_book_detail_screen.dart';
import 'widgets/catalog_book_card.dart';

/// "Ählisini gör" / "see more" destination for one real [Collection]'s full
/// book list — the real-catalogue counterpart to `CollectionBooksScreen`
/// (mock `Book`), reusing the same [CatalogBookCard] every other real-book
/// list in the app uses (Home's rows, [CatalogAuthorDetailScreen]) rather
/// than a one-off card design just for this grid.
class CatalogCollectionBooksScreen extends StatelessWidget {
  final String title;
  final List<LibraryBook> books;

  /// Set from [CatalogRankShelfCard]'s "Daha fazla" — that card already
  /// leads with a numbered top-4 list over a cover-image banner, so its
  /// "see more" continues that same ranked-list shape instead of switching
  /// to the plain grid the other (non-ranked) collection cards use.
  final bool ranked;

  const CatalogCollectionBooksScreen({super.key, required this.title, required this.books, this.ranked = false});

  @override
  Widget build(BuildContext context) {
    if (ranked) return _RankedCollectionView(title: title, books: books);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: books.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.5,
          ),
          itemBuilder: (context, i) => CatalogBookCard(book: books[i], width: double.infinity, coverHeight: 170, margin: EdgeInsets.zero),
        ),
      ),
    );
  }
}

class _RankedCollectionView extends StatelessWidget {
  final String title;
  final List<LibraryBook> books;
  const _RankedCollectionView({required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    final bannerImage = books.isNotEmpty ? books.first.image : null;
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
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _RankedCollectionBanner(imageUrl: bannerImage)),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            sliver: SliverList.builder(
              itemCount: books.length,
              itemBuilder: (context, i) => _StaggerFadeIn(
                index: i,
                child: _RankedListTile(rank: i + 1, book: books[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed banner behind the [SliverAppBar] — the top book's own cover,
/// same as [CatalogRankShelfCard]'s card header. Carries no text of its
/// own; the collection name lives in [FlexibleSpaceBar.title] instead so it
/// collapses into the toolbar properly.
class _RankedCollectionBanner extends StatelessWidget {
  final String? imageUrl;
  const _RankedCollectionBanner({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        hasImage ? NetworkCoverImage(url: ApiConfig.resolveImageUrl(url), placeholder: (_) => Container(color: AppColors.card)) : Container(color: AppColors.card),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.65)],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _RankedListTile extends StatelessWidget {
  final int rank;
  final LibraryBook book;
  const _RankedListTile({required this.rank, required this.book});

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: GestureDetector(
        onTap: () => context.push(CatalogBookDetailScreen(bookId: book.id)),
        // No fill — the row sits directly on the page background; only the
        // cover's own shadow (see [_BookCoverThumb]) gives it depth.
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(width: 22, child: Text('$rank', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              _BookCoverThumb(imageUrl: image),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.name, style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(book.authorNames, style: TextStyle(color: AppColors.grey2, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (book.pageCount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey2, size: 12),
                          const SizedBox(width: 4),
                          Text('${book.pageCount} ${BookDetailStrings.statPages}', style: TextStyle(color: AppColors.grey2, fontSize: 11.5)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The row's cover — a fixed width at the app's usual book aspect ratio
/// (0.62, same as [LibraryBookCover]) rather than the previous 52×74 box,
/// which slightly squashed every cover. Shadow lives on an outer
/// [DecoratedBox] and the image is clipped by an inner [ClipRRect] — put
/// both on the same box and `clipBehavior` cuts the shadow off along with
/// everything else outside the corners.
class _BookCoverThumb extends StatelessWidget {
  final String? imageUrl;
  const _BookCoverThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return SizedBox(
      width: 54,
      child: AspectRatio(
        aspectRatio: 0.62,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // Dark mode: a black shadow would just vanish into the dark
            // page background, so the cover gets a soft light glow instead;
            // light mode keeps the usual dark drop shadow.
            boxShadow: [
              BoxShadow(
                color: (AppTheme.instance.isDark ? Colors.white : Colors.black).withValues(alpha: AppTheme.instance.isDark ? 0.18 : 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: AppColors.surface,
              // The same placeholder covers both "still loading" and "no
              // cover url" — leaving it blank (as before) is what made a
              // cover read as missing until the network image finished.
              child: hasImage ? NetworkCoverImage(url: ApiConfig.resolveImageUrl(url), placeholder: (_) => _coverPlaceholder()) : _coverPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey3, size: 20));
}

/// Fades + slides each row in from below as it's built — [SliverList]
/// builds lazily, so this doubles as a "settle in as you scroll to it"
/// effect rather than the whole list popping in at once. The stagger is
/// capped at 300ms so a long list doesn't leave later rows waiting on a
/// delay that's already outlasted its purpose.
class _StaggerFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerFadeIn({required this.index, required this.child});

  @override
  State<_StaggerFadeIn> createState() => _StaggerFadeInState();
}

class _StaggerFadeInState extends State<_StaggerFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_fade);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 300));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
