import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../../core/services/sample_book_store.dart';
import '../../core/services/purchased_books_store.dart';
import '../../core/services/subscription_service.dart';
import '../../core/localization/strings/book_detail_strings.dart';
import '../author/author_screen.dart';
import '../payment/book_purchase_screen.dart';
import '../reader/provider/reader_provider.dart';
import '../reader/views/reader_view.dart';

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

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.load();
    PurchasedBooksStore.instance.load();
  }

  bool get _canRead => SubscriptionService.instance.isActive || PurchasedBooksStore.instance.isPurchased(widget.book.id);

  /// §10.2: a subscriber never sees "Satyn al" (the sticky CTA already hides
  /// it whenever [_canRead] is true), so reaching this method always means a
  /// real per-book purchase is needed.
  Future<void> _onBuy() async {
    final purchased = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookPurchaseScreen(book: widget.book)),
    );
    if (purchased == true) {
      await PurchasedBooksStore.instance.markPurchased(widget.book);
    }
  }

  bool _opening = false;

  /// Opens the real EPUB reader once the user is entitled to read (bought the
  /// book or holds an active subscription). Each mock book maps to one of the
  /// sample EPUBs in assets/books/ (see [SampleBookStore]) since there's no
  /// per-book backend content yet — that's a content-source stopgap, separate
  /// from the entitlement check above.
  Future<void> _openReader() async {
    if (_opening) return;
    setState(() => _opening = true);
    final book = widget.book;
    try {
      final path = await SampleBookStore.epubPathFor(book);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => ReaderProvider(),
            child: ReaderScreen(bookPath: path, bookId: book.id.hashCode, bookTitle: book.title),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(BookDetailStrings.openError(e))));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _toggleFinished() {
    setState(() => _isFinished = !_isFinished);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFinished ? BookDetailStrings.finishedAdded : BookDetailStrings.finishedRemoved)),
    );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFavorite ? BookDetailStrings.favoriteAdded : BookDetailStrings.favoriteRemoved)),
    );
  }

  void _onShare(Book book) {
    Share.share(BookDetailStrings.shareText(book.title, book.author.name));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final similar = MockData.generateBooks(8, seed: 40);
    final byAuthor = MockData.generateBooks(6, seed: 70);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeaderArt(context, book)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Text(book.title, textAlign: TextAlign.center, style: TextStyle(color: AppColors.white, fontSize: 23, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthorScreen(author: book.author))),
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
                  _buildStatsRow(book),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
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
                    children: book.genres.map((g) => _GenreTag(label: g)).toList(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildCarousel(BookDetailStrings.similarBooks, similar)),
          SliverToBoxAdapter(child: _buildCarousel(BookDetailStrings.moreByAuthor, byAuthor)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: _buildStickyCta(book),
    );
  }

  Widget _buildHeaderArt(BuildContext context, Book book) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred bg cover (§10.1.1). ClipRect is required here — an
          // unclipped BackdropFilter blurs the full scene layer rather than
          // just this Stack's bounds, so it visibly bleeds into the sliver
          // content below until a later frame (e.g. a scroll) forces Flutter
          // to re-establish the layer bounds.
          Image.asset(book.coverImage, fit: BoxFit.cover),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: book.coverColor.withValues(alpha: 0.55)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.bg.withValues(alpha: 0.4), AppColors.bg],
                stops: const [0.4, 0.82, 1.0],
              ),
            ),
          ),
          // Top bar — back on the left, flag / favourite / share on the right
          Positioned(
            top: topPad + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _RoundIconBtn(icon: HugeIcons.strokeRoundedArrowLeft01, onTap: () => Navigator.pop(context)),
                const Spacer(),
                _RoundIconBtn(
                  icon: HugeIcons.strokeRoundedFlag02,
                  active: _isFinished,
                  onTap: _toggleFinished,
                ),
                const SizedBox(width: 8),
                _RoundIconBtn(
                  icon: HugeIcons.strokeRoundedFavourite,
                  active: _isFavorite,
                  onTap: _toggleFavorite,
                ),
                const SizedBox(width: 8),
                _RoundIconBtn(icon: HugeIcons.strokeRoundedShare08, onTap: () => _onShare(book)),
              ],
            ),
          ),
          // Main cover (§10.1.2)
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 152,
                height: 224,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(book.coverImage, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// §10.1.5–6: read count · purchase count · pages, plus the format pill.
  Widget _buildStatsRow(Book book) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MetaStat(value: _fmt(book.readCount), label: BookDetailStrings.statRead),
            _MetaDivider(),
            _MetaStat(value: _fmt(book.purchaseCount), label: BookDetailStrings.statPurchased),
            _MetaDivider(),
            _MetaStat(value: '${book.pages}', label: BookDetailStrings.statPages),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedFile01, color: AppColors.grey2, size: 14),
              const SizedBox(width: 6),
              Text(book.format.label, style: TextStyle(color: AppColors.grey1, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
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
            itemBuilder: (_, i) {
              final b = books[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: b))),
                child: _MiniBookCard(book: b),
              );
            },
          ),
        ),
      ],
    );
  }

  /// §10.1.7 + §10.2 — pinned bottom action. Subscribers / owners get "Oka";
  /// everyone else sees the price and a "Satyn al" button. Listens to both
  /// entitlement sources directly so it flips the instant a purchase or a
  /// fresh subscription lands, without the rest of the screen rebuilding.
  Widget _buildStickyCta(Book book) {
    return ListenableBuilder(
      listenable: Listenable.merge([SubscriptionService.instance, PurchasedBooksStore.instance]),
      builder: (context, _) {
        final canRead = _canRead;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: canRead
                  ? SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _opening ? null : _openReader,
                        icon: _opening
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                            : const HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: Colors.white, size: 20),
                        label: Text(BookDetailStrings.read, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    )
                  : Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(BookDetailStrings.price, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(BookDetailStrings.priceValue(book.priceManat), style: TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: _onBuy,
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedShoppingBag01, color: Colors.white, size: 19),
                              label: Text(BookDetailStrings.buy, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// One "12.4K / okaldy" stacked stat in the centered meta row.
class _MetaStat extends StatelessWidget {
  final String value;
  final String label;
  const _MetaStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.border,
    );
  }
}

class _GenreTag extends StatelessWidget {
  final String label;
  const _GenreTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final bool active;
  final VoidCallback onTap;
  const _RoundIconBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: active ? AppColors.primary : Colors.white, size: 18),
      ),
    );
  }
}

class _MiniBookCard extends StatelessWidget {
  final Book book;
  const _MiniBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 155,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(book.coverImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          Text(book.title, style: TextStyle(color: AppColors.grey1, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(book.author.name, style: TextStyle(color: AppColors.grey2, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
