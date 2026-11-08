import 'package:flutter/material.dart';
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
import 'widgets/catalog_author_avatar.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _name = HomeStrings.defaultReaderName;

  // One-shot fade-in for the skeleton→content handoff: a single opacity ramp
  // on the incoming lazy sliver, not [AnimatedSwitcher] — that would need
  // both the skeleton and every collection section built at once to
  // cross-fade between them, which is exactly the eager-build cost the lazy
  // [SliverList.builder] in [_buildRevealedContent] exists to avoid.
  //
  // Built eagerly in [initState], not via a lazy `late` initializer on the
  // field: [_buildRevealedContent] (the only place that would otherwise
  // touch this field first) never runs at all while Home stays on the
  // empty/error state for its whole lifetime, which left the ticker's first
  // construction to happen inside [dispose] — by then the element is
  // already deactivated, and `SingleTickerProviderStateMixin.createTicker`'s
  // `TickerMode` ancestor lookup throws.
  late final AnimationController _contentFadeController;
  late final Animation<double> _contentFade;
  bool _contentRevealed = false;

  @override
  void initState() {
    super.initState();
    _contentFadeController =
        AnimationController(vsync: this, duration: AppMotion.crossfade);
    _contentFade = CurvedAnimation(
        parent: _contentFadeController, curve: AppMotion.easeOut);
    _loadName();
    StreakService.instance.load();
    // Fallback only — the splash screen already kicked this off. Idempotent,
    // so this is a no-op on the normal path (already loading/loaded by the
    // time Home mounts).
    HomeDataService.instance.load();
  }

  @override
  void dispose() {
    _contentFadeController.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final name = await AuthSession.getName();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _name = name);
    }
  }

  /// Plays exactly once — for the first successful collections response.
  /// A later manual [HomeDataService.reload] intentionally does not replay
  /// it (matching the eased-in shimmer→content handoff being a first-load
  /// affordance, not something worth repeating every retry).
  void _revealContentOnce(BuildContext context) {
    if (_contentRevealed) return;
    _contentRevealed = true;
    if (AppMotion.reduceMotion(context)) {
      _contentFadeController.value = 1;
    } else {
      _contentFadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Scoped to collections only — a banner or loading change
              // never runs this builder, and vice versa (loading only
              // reaches the small retry state nested below).
              ValueListenableBuilder<List<Collection>?>(
                valueListenable: HomeDataService.instance.collectionsListenable,
                builder: (context, collections, _) {
                  if (collections == null) {
                    return const SliverToBoxAdapter(
                        child: HomeShimmer(key: ValueKey('home-shimmer')));
                  }
                  if (HomeDataService.instance.hasNoContent) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: ValueListenableBuilder<bool>(
                        valueListenable:
                            HomeDataService.instance.loadingListenable,
                        builder: (context, loading, __) => HomeReloadState(
                          loading: loading,
                          onReload: HomeDataService.instance.reload,
                        ),
                      ),
                    );
                  }
                  return _buildRevealedContent(
                      context, _groupByQueuePosition(collections));
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 74,
            left: 16,
            right: 16,
            child: HomeConnectionBanner(
              onReconnected: HomeDataService.instance.refreshInBackground,
            ),
          ),
        ],
      ),
    );
  }

  /// The real content, one lazy list item per [_groupByQueuePosition] group
  /// — only groups near the viewport are ever built, unlike the eager
  /// [Column] this replaced. [StaggerFadeIn]'s own
  /// [AutomaticKeepAliveClientMixin] is what keeps a section's entrance from
  /// replaying if it's scrolled out past the cache extent and back; a group
  /// built for the first time (freshly scrolled into range) still gets its
  /// own one-time entrance, same as before.
  Widget _buildRevealedContent(
      BuildContext context, List<List<Collection>> groups) {
    _revealContentOnce(context);
    return AnimatedBuilder(
      animation: _contentFade,
      builder: (context, sliver) =>
          SliverOpacity(opacity: _contentFade.value, sliver: sliver!),
      child: SliverList.builder(
        itemCount: groups.length,
        itemBuilder: (context, i) => StaggerFadeIn(
          key: ValueKey(
              '${groups[i].first.queuePosition}-${groups[i].first.id}'),
          index: i,
          child: groups[i].length > 1
              ? _buildGenreShelfRow(context, groups[i])
              : _buildCollectionEntry(
                  context, groups[i].first, StaggerFadeIn.delayFor(i)),
        ),
      ),
    );
  }
}
