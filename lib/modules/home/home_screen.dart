import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/home_strings.dart';
import '../../core/models/collection.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_hero_tags.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/home_data_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/section_header.dart';
import '../streak/streak_screen.dart';
import 'catalog_collection_books_screen.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/catalog_author_card.dart';
import 'widgets/catalog_book_card.dart';
import 'widgets/catalog_numbered_book_section.dart';
import 'widgets/catalog_rank_shelf_card.dart';
import 'widgets/catalog_series_card.dart';
import 'widgets/home_connection_banner.dart';
import 'widgets/home_header.dart';
import 'widgets/home_reload_state.dart';
import 'widgets/home_shimmer.dart';
import 'widgets/stagger_fade_in.dart';

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
    final groups =
        collections == null ? null : _groupByQueuePosition(collections);
    final reduceMotion = AppMotion.reduceMotion(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeader(
                  name: _name,
                  onStreakTap: () => context.push(const StreakScreen()),
                ),
              ),
              const SliverToBoxAdapter(child: BannerCarousel()),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
              if (collections != null && homeData.hasNoContent)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: HomeReloadState(
                    loading: homeData.isLoading,
                    onReload: homeData.reload,
                  ),
                )
              else
                // Skeleton → content is the only cross-fade here: banner and
                // header are their own slivers above and never re-animate,
                // and each section's own entrance is [StaggerFadeIn]'s job,
                // not this switcher's. One entrance per successful result —
                // a manual reload replaces the whole content subtree and
                // earns one fresh stagger; scrolling this SliverToBoxAdapter
                // out of view and back does not, since it isn't lazy.
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration:
                        reduceMotion ? Duration.zero : AppMotion.crossfade,
                    switchInCurve: AppMotion.easeOut,
                    switchOutCurve: AppMotion.easeOut,
                    child: collections == null
                        ? const HomeShimmer(key: ValueKey('home-shimmer'))
                        : KeyedSubtree(
                            key: const ValueKey('home-content'),
                            child: Column(
                              children: [
                                for (var i = 0; i < groups!.length; i++)
                                  StaggerFadeIn(
                                    key: ValueKey(
                                      '${groups[i].first.queuePosition}-'
                                      '${groups[i].first.id}',
                                    ),
                                    index: i,
                                    child: groups[i].length > 1
                                        ? _buildGenreShelfRow(
                                            context, groups[i])
                                        : _buildCollectionEntry(
                                            context,
                                            groups[i].first,
                                            StaggerFadeIn.delayFor(i)),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 74,
            left: 16,
            right: 16,
            child: HomeConnectionBanner(
              onReconnected: homeData.refreshInBackground,
            ),
          ),
        ],
      ),
    );
  }
}
