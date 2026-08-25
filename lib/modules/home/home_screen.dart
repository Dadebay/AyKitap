import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/home_strings.dart';
import '../../core/models/collection.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/home_data_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/section_header.dart';
import '../streak/streak_screen.dart';
import 'catalog_collection_books_screen.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/catalog_author_card.dart';
import 'widgets/catalog_book_card.dart';
import 'widgets/catalog_rank_shelf_card.dart';
import 'widgets/catalog_series_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_reload_state.dart';
import 'widgets/home_shimmer.dart';

part 'home_screen_sections.dart';

/// Home tab — every section below the header/banner comes straight from
/// `GET /collections/all` ([HomeDataService], prefetched starting at the
/// splash screen); nothing here is mock catalogue data. Search still runs
/// on the mock catalogue ([MockData]) — that migration is a separate,
/// much larger piece of work.
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
    // Fallback only — the splash screen already kicked this off. Idempotent,
    // so this is a no-op on the normal path (already loading/loaded by the
    // time Home mounts).
    HomeDataService.instance.load();
  }

  Future<void> _loadName() async {
    final name = await AuthSession.getName();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _name = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeData = context.watch<HomeDataService>();
    final collections = homeData.collections;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              name: _name,
              onStreakTap: () => context.push(const StreakScreen()),
            ),
          ),
          const SliverToBoxAdapter(child: BannerCarousel()),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          if (collections == null)
            const SliverToBoxAdapter(child: HomeShimmer())
          else if (homeData.hasNoContent)
            SliverFillRemaining(
              hasScrollBody: false,
              child: HomeReloadState(
                loading: homeData.isLoading,
                onReload: homeData.reload,
              ),
            )
          else
            // "Täze gelenler", "Hepdelik iň köp okalanlar", "Rus Ýazarlar",
            // ... — one stacked straight from `GET /collections/all`, in
            // whatever order/count the backend sends. Consecutive entries
            // that share the same `queue_position` (e.g. "Biznes / Maliýe",
            // "Şahsy Ösüş", "Psihologiýa", "Liderlik" all at 41) are meant to
            // sit side by side as one horizontal row instead of each getting
            // its own stacked section — see [_groupByQueuePosition].
            for (final group in _groupByQueuePosition(collections))
              SliverToBoxAdapter(
                child: group.length > 1
                    ? _buildGenreShelfRow(context, group)
                    : _buildCollectionEntry(context, group.first),
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
