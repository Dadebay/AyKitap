import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../../core/data/mock/mock_data.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/sample_book_store.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/purchased_books_store.dart';
import '../../core/services/subscription_service.dart';
import '../../core/localization/strings/book_detail_strings.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/book_card.dart';
import '../author/author_screen.dart';
import '../payment/book_purchase_screen.dart';
import '../reader/provider/reader_provider.dart';
import '../reader/views/reader_view.dart';
import 'widgets/detail_header_art.dart';
import 'widgets/detail_header_controls.dart';
import 'widgets/detail_stats_row.dart';
import 'widgets/detail_sticky_cta.dart';
import 'widgets/genre_tag.dart';

/// Kitap Maglumatlary Sahypasy — TZ section 10.
class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isFavorite = false;
  bool _isFinished = false;
  bool _synopsisExpanded = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.load();
    PurchasedBooksStore.instance.load();
    // Every visit to a book's detail page, regardless of whether the user
    // goes on to read it — this is what "most-viewed book" reports read off.
    AnalyticsService.instance.logSelectBook(id: widget.book.id, title: widget.book.title);
  }

  /// §10.2: a subscriber never sees "Satyn al" (the sticky CTA already hides
  /// it whenever the user is entitled), so reaching this method always means
  /// a real per-book purchase is needed.
  Future<void> _onBuy() async {
    final purchased = await context.push<bool>(BookPurchaseScreen(book: widget.book));
    if (purchased == true) {
      await PurchasedBooksStore.instance.markPurchased(widget.book);
    }
  }

  /// Opens the real EPUB reader once the user is entitled to read (bought the
  /// book or holds an active subscription). Each mock book maps to one of the
  /// sample EPUBs in assets/books/ (see [SampleBookStore]) since there's no
  /// per-book backend content yet — that's a content-source stopgap, separate
  /// from the entitlement check in [DetailStickyCta].
  Future<void> _openReader() async {
    if (_opening) return;
    setState(() => _opening = true);
    final book = widget.book;
    try {
      final path = await SampleBookStore.epubPathFor(book);
      if (!mounted) return;
      // Fires on an actual "start reading", separate from the [logSelectBook]
      // view event in initState — this is the "most-opened book" signal.
      AnalyticsService.instance.logBookOpened(id: book.id, format: book.format.label);
      await context.push(
        ChangeNotifierProvider(
          create: (_) => ReaderProvider(),
          child: ReaderScreen(bookPath: path, bookId: book.id.hashCode, bookTitle: book.title),
        ),
      );
    } catch (e) {
      if (mounted) context.showAppSnackBar(BookDetailStrings.openError(e));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _toggleFinished() {
    setState(() => _isFinished = !_isFinished);
    context.showAppSnackBar(_isFinished ? BookDetailStrings.finishedAdded : BookDetailStrings.finishedRemoved);
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    context.showAppSnackBar(_isFavorite ? BookDetailStrings.favoriteAdded : BookDetailStrings.favoriteRemoved);
  }

  void _onShare(Book book) {
    Share.share(BookDetailStrings.shareText(book.title, book.author.name));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final similar = MockData.generateBooks(8, seed: 40);
    final byAuthor = MockData.generateBooks(6, seed: 70);

    // DetailHeaderArt (400px) is a fixed backdrop, not a scroll item — it
    // sits pinned at the very bottom of the stack. The content sheet scrolls
    // in its own layer above it, starting a little shy of the header's
    // bottom edge so it can be dragged up to ride over the book cover.
    // DetailHeaderControls (back/flag/favorite/share) sits in its own layer
    // on top of *that*, so those buttons stay tappable no matter how far
    // the sheet has scrolled up over the header.
    const headerHeight = 400.0;
    const sheetOverlap = 30.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, height: headerHeight, child: DetailHeaderArt(book: book)),
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: headerHeight - sheetOverlap)),
              SliverToBoxAdapter(child: _buildContentSheet(context, book, similar, byAuthor)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DetailHeaderControls(
              isFinished: _isFinished,
              isFavorite: _isFavorite,
              onBack: () => Navigator.pop(context),
              onToggleFinished: _toggleFinished,
              onToggleFavorite: _toggleFavorite,
              onShare: () => _onShare(book),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DetailStickyCta(book: book, opening: _opening, onRead: _openReader, onBuy: _onBuy),
    );
  }

  // Everything below the hero lives on one rounded "sheet" — a surface a
  // shade lighter than the scaffold background. It's the sliver that
  // actually scrolls: it starts a bit shy of the pinned header's bottom
  // edge (see `sheetOverlap` in build()) and, as the page is dragged up,
  // rides higher and higher over the fixed book cover behind it.
  Widget _buildContentSheet(BuildContext context, Book book, List<Book> similar, List<Book> byAuthor) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(38), topRight: Radius.circular(38)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(38), topRight: Radius.circular(38)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, -6))],
        ),
        child: Column(
          children: [
            _buildTitleBlock(context, book),
            _buildAboutBlock(book),
            _buildCarousel(BookDetailStrings.similarBooks, similar),
            _buildCarousel(BookDetailStrings.moreByAuthor, byAuthor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBlock(BuildContext context, Book book) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Text(book.title, textAlign: TextAlign.center, style: TextStyle(color: AppColors.white, fontSize: 23, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push(AuthorScreen(author: book.author)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(book.author.name, style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(width: 3),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.primary, size: 15),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DetailStatsRow(book: book),
        ],
      ),
    );
  }

  Widget _buildAboutBlock(Book book) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(BookDetailStrings.aboutBook, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _buildSynopsis(book),
          const SizedBox(height: 20),
          Text(BookDetailStrings.genres, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: book.genres.map((g) => GenreTag(label: g)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsis(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.synopsis,
          maxLines: _synopsisExpanded ? null : 3,
          overflow: _synopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.grey1, fontSize: 14, height: 1.55),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _synopsisExpanded = !_synopsisExpanded),
          child: Text(
            _synopsisExpanded ? BookDetailStrings.showLess : BookDetailStrings.readFull,
            style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel(String title, List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text(title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (_, i) => BookCard(
              book: books[i],
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              onTap: () => context.push(BookDetailScreen(book: books[i])),
            ),
          ),
        ),
      ],
    );
  }
}
