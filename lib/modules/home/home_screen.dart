import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/home_strings.dart';
import '../../core/models/book.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/streak_service.dart';
import '../../core/widgets/streak_flame.dart';
import '../author/author_screen.dart';
import '../book_detail/book_detail_screen.dart';
import '../notifications/notification_screen.dart';
import '../popular/collection_books_screen.dart';
import '../series/all_series_screen.dart';
import '../streak/streak_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = HomeStrings.defaultReaderName;

  @override
  void initState() {
    super.initState();
    _loadName();
    StreakService.instance.load();
  }

  Future<void> _loadName() async {
    final name = await AuthSession.getName();
    if (mounted && name != null && name.isNotEmpty) setState(() => _name = name);
  }

  // Täze Gelenler / Hepdelik Iň Köp Okunanlar / Bestsellers / Redaktoryň
  // Saýlawlary come first in MockData.homeSections; Kolleksiýalar sits
  // right after them and before the genre rows.
  static const _topSectionsCount = 4;

  @override
  Widget build(BuildContext context) {
    final sections = MockData.homeSections;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          const SliverToBoxAdapter(child: _BannerCarousel()),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          SliverToBoxAdapter(child: _buildSection(context, HomeStrings.popularBooks, seed: 99)),
          SliverToBoxAdapter(child: _buildPopularRankCard(context)),
          for (int i = 0; i < _topSectionsCount; i++) SliverToBoxAdapter(child: _buildSection(context, sections[i].title, subtitle: sections[i].subtitle, seed: i * 3)),
          SliverToBoxAdapter(child: _buildCollectionsRow(context)),
          SliverToBoxAdapter(child: _buildSeriesRow(context)),
          SliverToBoxAdapter(child: _buildAuthorsRow(context)),
          for (int i = _topSectionsCount; i < sections.length; i++) SliverToBoxAdapter(child: _buildSection(context, sections[i].title, subtitle: sections[i].subtitle, seed: i * 3)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: HomeStrings.welcomePrefix, style: TextStyle(color: AppColors.grey2, fontSize: 18)),
                  TextSpan(text: _name, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ListenableBuilder(
            listenable: StreakService.instance,
            builder: (context, _) => _StreakPill(
              days: StreakService.instance.currentStreak,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen())),
            ),
          ),
          _IconBtn(
            icon: HugeIcons.strokeRoundedNotification01,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, {required int seed, String? subtitle}) {
    final books = MockData.generateBooks(15, seed: seed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle, style: TextStyle(color: AppColors.grey2, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CollectionBooksScreen(title: title, books: MockData.generateBooks(30, seed: seed))),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(HomeStrings.seeAll, style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: books[i]))),
              child: _BookCard(book: books[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsRow(BuildContext context) {
    final collections = MockData.collections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(HomeStrings.collections, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        CarouselSlider.builder(
          itemCount: collections.length,
          options: CarouselOptions(
            height: 150,
            viewportFraction: 0.62,
            enlargeCenterPage: true,
            enlargeFactor: 0.18,
            enableInfiniteScroll: false,
            padEnds: false,
          ),
          itemBuilder: (context, i, realIdx) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CollectionBooksScreen(title: collections[i].title, books: collections[i].books)),
              ),
              child: _CollectionCard(collection: collections[i]),
            ),
          ),
        ),
      ],
    );
  }

  // Serialar üçin Kolleksiýa v2 — the first 10 series as big image cards in
  // a horizontal row; "Ählisi" opens the full list of every series.
  Widget _buildSeriesRow(BuildContext context) {
    final series = MockData.series.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(HomeStrings.series, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllSeriesScreen())),
                child: Text(HomeStrings.seriesSeeAll, style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: series.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => SizedBox(
              width: 180,
              child: SeriesCard(series: series[i]),
            ),
          ),
        ),
      ],
    );
  }

  // Ýazarlar row — TZ section 11: a horizontal strip of author avatars,
  // "Ählisini gör" opens the full grid (AllAuthorsScreen).
  Widget _buildAuthorsRow(BuildContext context) {
    final authors = MockData.authors.take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(HomeStrings.authors, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAuthorsScreen())),
                child: Text(HomeStrings.seeAll, style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 146,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: authors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthorScreen(author: authors[i]))),
              child: _AuthorAvatar(author: authors[i]),
            ),
          ),
        ),
      ],
    );
  }

  // Several "İlk 100"-style shelf cards — swiping the outer carousel moves
  // between whole cards (the next one peeks at the right edge), each with
  // its own banner photo, tag, and top-5 ranking.
  List<_RankShelf> get _rankShelves {
    final byReadCount = [...MockData.books]..sort((a, b) => b.readCount.compareTo(a.readCount));
    return [
      _RankShelf(
        tag: HomeStrings.rankTagTop100,
        subtitle: HomeStrings.rankSubtitleTop100,
        bannerImage: 'assets/images/banners/banner_04.jpg',
        books: byReadCount.take(4).toList(),
        allBooks: byReadCount,
      ),
      _RankShelf(
        tag: HomeStrings.rankTagEditorsChoice,
        subtitle: HomeStrings.rankSubtitleEditorsChoice,
        bannerImage: 'assets/images/banners/banner_02.jpg',
        books: MockData.generateBooks(4, seed: 77),
        allBooks: MockData.generateBooks(50, seed: 77),
      ),
      _RankShelf(
        tag: HomeStrings.rankTagNewlyAdded,
        subtitle: HomeStrings.rankSubtitleNewlyAdded,
        bannerImage: 'assets/images/banners/banner_01.jpg',
        books: MockData.generateBooks(4, seed: 12),
        allBooks: MockData.generateBooks(50, seed: 12),
      ),
    ];
  }

  Widget _buildPopularRankCard(BuildContext context) {
    final shelves = _rankShelves;
    return CarouselSlider.builder(
      itemCount: shelves.length,
      options: CarouselOptions(
        height: 465,
        viewportFraction: 0.92,
        enableInfiniteScroll: false,
        padEnds: false,
      ),
      itemBuilder: (context, i, realIdx) => Padding(
        padding: const EdgeInsets.only(right: 10, left: 10, top: 20, bottom: 8),
        child: _RankShelfCard(shelf: shelves[i]),
      ),
    );
  }
}

class _RankShelf {
  final String tag;
  final String subtitle;
  final String bannerImage;
  final List<Book> books;
  final List<Book> allBooks;
  const _RankShelf({required this.tag, required this.subtitle, required this.bannerImage, required this.books, required this.allBooks});
}

class _RankShelfCard extends StatelessWidget {
  final _RankShelf shelf;
  const _RankShelfCard({required this.shelf});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 84,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(shelf.bannerImage, fit: BoxFit.cover),
                  // Scrim so the white text stays legible over the photo.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.15)],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shelf.tag, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(shelf.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                      child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBookmark02, color: Colors.white, size: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: Column(
              children: [
                for (int i = 0; i < shelf.books.length; i++) ...[
                  _RankedBookTile(rank: i + 1, book: shelf.books[i]),
                  if (i != shelf.books.length - 1) const SizedBox(height: 12),
                ],
                Container(
                  width: double.infinity,
                  height: 46,
                  margin: const EdgeInsets.only(top: 14),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CollectionBooksScreen(title: shelf.tag, books: shelf.allBooks)),
                    ),
                    child: Text(HomeStrings.seeMore, style: TextStyle(color: AppColors.grey1, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final BookCollection collection;
  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: collection.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: collection.gradient.last.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Center(child: Text(collection.emoji, style: const TextStyle(fontSize: 22))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collection.title,
                style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.25),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
                    child: Text(HomeStrings.bookCount(collection.books.length), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.white, size: 14)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single circle-avatar + name cell in the HomeScreen "Ýazarlar" row —
/// same colored-circle-with-user-icon placeholder as [AllAuthorsScreen],
/// just sized to sit in a horizontal strip instead of a grid.
class _AuthorAvatar extends StatelessWidget {
  final Author author;
  const _AuthorAvatar({required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: author.color, shape: BoxShape.circle),
            child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.white70, size: 26)),
          ),
          const SizedBox(height: 10),
          Text(
            author.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.grey1, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RankedBookTile extends StatelessWidget {
  final int rank;
  final Book book;
  const _RankedBookTile({required this.rank, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: book))),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$rank', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            height: 56,
            child: Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(book.coverImage, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(book.author.name, style: TextStyle(color: AppColors.grey2, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int days;
  final VoidCallback? onTap;
  const _StreakPill({required this.days, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.only(left: 4, right: 16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StreakFlame(size: 30),
            const SizedBox(width: 3),
            Text('$days', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: HugeIcon(icon: icon, color: AppColors.grey1, size: 20),
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String image;
  const _BannerData({required this.title, required this.subtitle, required this.image});
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  // Not `const` (unlike the rest of this file's static data) because each
  // title/subtitle now goes through `t()`, which reads the live locale —
  // a getter re-evaluates it on every build instead of baking in `tk` text.
  static List<_BannerData> get _banners => [
        _BannerData(
          title: HomeStrings.banner1Title,
          subtitle: HomeStrings.banner1Subtitle,
          image: 'assets/images/banners/banner_01.jpg',
        ),
        _BannerData(
          title: HomeStrings.banner2Title,
          subtitle: HomeStrings.banner2Subtitle,
          image: 'assets/images/banners/banner_02.jpg',
        ),
        _BannerData(
          title: HomeStrings.banner3Title,
          subtitle: HomeStrings.banner3Subtitle,
          image: 'assets/images/banners/banner_03.jpg',
        ),
        _BannerData(
          title: HomeStrings.banner4Title,
          subtitle: HomeStrings.banner4Subtitle,
          image: 'assets/images/banners/banner_04.jpg',
        ),
      ];

  late final PageController _controller = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            // No itemCount — an infinite forward index range, wrapped into
            // the 4 real banners below, so paging past the last one loops
            // straight back to the first.
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _BannerCard(data: _banners[i % _banners.length]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          // Read the active dot straight off the controller — same modulo
          // math the itemBuilder above uses — instead of a separate int
          // that can drift out of sync with what's actually on screen.
          animation: _controller,
          builder: (context, _) {
            final raw = _controller.hasClients ? (_controller.page ?? 0) : 0.0;
            final active = raw.round() % _banners.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (i) {
                final isActive = i == active;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: isActive ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(data.image, fit: BoxFit.cover),
          // Scrim so the white title/subtitle stay legible over any photo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 6),
                Text(data.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 6, right: 10),
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
