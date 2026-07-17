import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/data/mock/mock_data.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/home_strings.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/streak_service.dart';
import '../../core/widgets/book_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/series_card.dart';
import '../author/author_screen.dart';
import '../book_detail/book_detail_screen.dart';
import '../notifications/notification_screen.dart';
import '../popular/collection_books_screen.dart';
import '../series/all_series_screen.dart';
import '../streak/streak_screen.dart';
import 'widgets/author_avatar.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/bundled_books_debug_screen.dart';
import 'widgets/collection_card.dart';
import 'widgets/home_header.dart';
import 'widgets/rank_shelf_card.dart';

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
          SliverToBoxAdapter(
            child: HomeHeader(
              name: _name,
              onStreakTap: () => context.push(const StreakScreen()),
              onNotificationsTap: () => context.push(const NotificationScreen()),
            ),
          ),
          const SliverToBoxAdapter(child: BannerCarousel()),
          SliverToBoxAdapter(child: _buildBundledBooksEntry(context)),
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

  /// Dev-only shortcut to [BundledBooksDebugScreen]. The catalogue maps mock
  /// books onto sample EPUBs by hash, so there's no way to tell from a cover
  /// which file it will open — this reaches the files directly, by name.
  /// Remove along with the debug screen once the backend serves real content.
  Widget _buildBundledBooksEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(const BundledBooksDebugScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.bug_report_outlined, color: AppColors.primary, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    HomeStrings.bundledBooksTitle,
                    style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.grey3, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, {required int seed, String? subtitle}) {
    final books = MockData.generateBooks(15, seed: seed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          seeAllLabel: HomeStrings.seeAll,
          onSeeAll: () => context.push(CollectionBooksScreen(title: title, books: MockData.generateBooks(30, seed: seed))),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (_, i) => BookCard(book: books[i], onTap: () => context.push(BookDetailScreen(book: books[i]))),
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
        SectionHeader(title: HomeStrings.collections),
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
              onTap: () => context.push(CollectionBooksScreen(title: collections[i].title, books: collections[i].books)),
              child: CollectionCard(collection: collections[i]),
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
    final cardWidth = MediaQuery.of(context).size.width * 0.74;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: HomeStrings.series, seeAllLabel: HomeStrings.seriesSeeAll, onSeeAll: () => context.push(const AllSeriesScreen())),
        SizedBox(
          height: cardWidth * 1.10,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: series.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: cardWidth,
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
        SectionHeader(title: HomeStrings.authors, seeAllLabel: HomeStrings.seeAll, onSeeAll: () => context.push(const AllAuthorsScreen())),
        SizedBox(
          height: 146,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: authors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => context.push(AuthorScreen(author: authors[i])),
              child: AuthorAvatar(author: authors[i]),
            ),
          ),
        ),
      ],
    );
  }

  // Several "İlk 100"-style shelf cards — swiping the outer carousel moves
  // between whole cards (the next one peeks at the right edge), each with
  // its own banner photo, tag, and top-5 ranking.
  List<RankShelf> get _rankShelves {
    final byReadCount = [...MockData.books]..sort((a, b) => b.readCount.compareTo(a.readCount));
    return [
      RankShelf(
        tag: HomeStrings.rankTagTop100,
        subtitle: HomeStrings.rankSubtitleTop100,
        bannerImage: 'assets/images/banners/banner_04.jpg',
        books: byReadCount.take(4).toList(),
        allBooks: byReadCount,
      ),
      RankShelf(
        tag: HomeStrings.rankTagEditorsChoice,
        subtitle: HomeStrings.rankSubtitleEditorsChoice,
        bannerImage: 'assets/images/banners/banner_02.jpg',
        books: MockData.generateBooks(4, seed: 77),
        allBooks: MockData.generateBooks(50, seed: 77),
      ),
      RankShelf(
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
        child: RankShelfCard(shelf: shelves[i]),
      ),
    );
  }
}
