import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/home_strings.dart';

/// The auto-advancing promo banner strip at the top of Home, with its own
/// dot indicator driven straight off the [PageController].
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerData {
  final String title;
  final String subtitle;
  final String image;
  const _BannerData({required this.title, required this.subtitle, required this.image});
}

class _BannerCarouselState extends State<BannerCarousel> {
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
