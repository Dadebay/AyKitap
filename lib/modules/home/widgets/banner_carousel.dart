import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/strings/home_strings.dart';
import '../../../core/models/promo_banner.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/home_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import 'home_shimmer.dart';

/// The auto-advancing promo banner strip at the top of Home. Data comes
/// from [HomeDataService] (prefetched starting at the splash screen, not
/// fetched by this widget itself); tapping a banner opens its `book_id` in
/// [CatalogBookDetailScreen] when present, else its `link` in the browser.
/// Its own dot indicator is driven straight off the [PageController].
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _controller = PageController();
  Timer? _timer;
  bool _autoAdvanceStarted = false;

  /// Starts or stops the auto-advance timer to match the current banner
  /// count — called on every rebuild (banner count can shrink as well as
  /// grow, e.g. a background refresh dropping to 0/1 banners) rather than
  /// only ever starting it once.
  void _syncAutoAdvance(List<PromoBanner>? banners, bool visible) {
    final canAdvance = visible && banners != null && banners.length > 1;
    if (canAdvance) {
      _startAutoAdvance();
    } else {
      _stopAutoAdvance();
    }
  }

  void _startAutoAdvance() {
    if (_autoAdvanceStarted) return;
    _autoAdvanceStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.nextPage(
          duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  void _stopAutoAdvance() {
    if (!_autoAdvanceStarted) return;
    _autoAdvanceStarted = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openBanner(PromoBanner banner) async {
    final bookId = banner.bookId;
    if (bookId != null) {
      context.pushFade(CatalogBookDetailScreen(bookId: bookId));
      return;
    }
    final link = banner.link;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      context.showAppSnackBar(HomeStrings.bannerLinkOpenError, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = TickerMode.valuesOf(context).enabled;
    return ValueListenableBuilder<List<PromoBanner>?>(
      valueListenable: HomeDataService.instance.bannersListenable,
      builder: (context, banners, _) {
        _syncAutoAdvance(banners, visible);
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: banners == null
              ? const BannerShimmer()
              : banners.isEmpty
                  ? const SizedBox.shrink()
                  : _buildCarousel(banners),
        );
      },
    );
  }

  Widget _buildCarousel(List<PromoBanner> banners) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final cardWidth = (constraints.maxWidth - 40).clamp(0.0, 800.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              // Keep the tablet artwork close to its source aspect ratio.
              // The old 300-high, full-width card cropped nearly half of it.
              height: isTablet ? cardWidth / 1.85 : 180,
              child: PageView.builder(
                controller: _controller,
                // No itemCount — an infinite forward index range, wrapped
                // into the real banners below.
                itemBuilder: (_, i) {
                  final banner = banners[i % banners.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _BannerCard(
                          banner: banner,
                          isTablet: isTablet,
                          onTap: () => _openBanner(banner),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                // Read the active dot straight off the controller — same modulo
                // math the itemBuilder above uses — instead of a separate int
                // that can drift out of sync with what's actually on screen.
                animation: _controller,
                builder: (context, _) {
                  final raw =
                      _controller.hasClients ? (_controller.page ?? 0) : 0.0;
                  final active = raw.round() % banners.length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(banners.length, (i) {
                      final isActive = i == active;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color:
                              isActive ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final bool isTablet;
  final VoidCallback onTap;
  const _BannerCard({
    required this.banner,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = banner.bookId != null ||
        (banner.link != null && banner.link!.isNotEmpty);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: isTablet ? AppColors.bg : AppColors.card,
        child: InkWell(
          onTap: hasAction ? onTap : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                // The supplied web artwork has a thin black frame baked
                // into its pixels. A small overscan hides it at both sizes.
                scale: isTablet ? 1.05 : 1.03,
                child: NetworkCoverImage(
                  url: ApiConfig.resolveImageUrl(
                      isTablet && banner.websiteImage.isNotEmpty
                          ? banner.websiteImage
                          : banner.mobileImage),
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_) => Container(color: AppColors.card),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      banner.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2),
                    ),
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
