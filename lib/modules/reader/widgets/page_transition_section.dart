import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../provider/reader_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/reader_strings.dart';

// Artwork lives in assets/icons/reader/, in the same order as
// ReaderPageTransition. The PNGs are transparent silhouettes, so they get
// tinted at paint time to follow the selected/idle state.
const _kTransitionIcons = {
  ReaderPageTransition.slide: 'assets/icons/reader/transition_slide.png',
  ReaderPageTransition.curl: 'assets/icons/reader/transition_curl.png',
  ReaderPageTransition.overlay: 'assets/icons/reader/transition_overlay.png',
  ReaderPageTransition.scroll: 'assets/icons/reader/transition_scroll.png',
  ReaderPageTransition.shift: 'assets/icons/reader/transition_shift.png',
  ReaderPageTransition.none: 'assets/icons/reader/transition_none.png',
};

String _labelFor(ReaderPageTransition t) => switch (t) {
      ReaderPageTransition.slide => ReaderStrings.transitionSlide,
      ReaderPageTransition.curl => ReaderStrings.transitionCurl,
      ReaderPageTransition.overlay => ReaderStrings.transitionOverlay,
      ReaderPageTransition.scroll => ReaderStrings.transitionScroll,
      ReaderPageTransition.shift => ReaderStrings.transitionShift,
      ReaderPageTransition.none => ReaderStrings.transitionNone,
    };

/// TZ §12.2 — the "Sahypa çalyşmak" row inside [ReaderSettingsSheet]. Rather
/// than expanding inline, it opens [PageTransitionSheet] as its own modal —
/// each settings group gets its own popup, matching the reference design.
class PageTransitionRow extends StatelessWidget {
  const PageTransitionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        return Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedArrowLeftRight, color: AppColors.primary, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ReaderStrings.pageTransitionTitle,
                      style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(_labelFor(provider.pageTransition), style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppColors.grey3, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const PageTransitionSheet(),
      ),
    );
  }
}

/// The "Sahypa çalyşmak" popup: a centred title with a close button, two rows
/// of three page-change styles, and the "flip with the left hand" toggle.
class PageTransitionSheet extends StatelessWidget {
  const PageTransitionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Centred title, with a close button balanced by an equal-width
              // spacer on the left so the text doesn't drift off-centre.
              Row(
                children: [
                  const SizedBox(width: 30),
                  Expanded(
                    child: Text(
                      ReaderStrings.pageTransitionTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                      child: Icon(Icons.close, color: AppColors.grey2, size: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row(provider, const [
                        ReaderPageTransition.slide,
                        ReaderPageTransition.curl,
                        ReaderPageTransition.overlay,
                      ]),
                      const SizedBox(height: 14),
                      _row(provider, const [
                        ReaderPageTransition.scroll,
                        ReaderPageTransition.shift,
                        ReaderPageTransition.none,
                      ]),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(ReaderProvider provider, List<ReaderPageTransition> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _TransitionTile(
              asset: _kTransitionIcons[items[i]]!,
              label: _labelFor(items[i]),
              selected: provider.pageTransition == items[i],
              onTap: () => provider.setPageTransition(items[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// One option: the artwork on a square tile, with its name beneath — filled
/// solid when selected, outlined when idle.
class _TransitionTile extends StatelessWidget {
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TransitionTile({required this.asset, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 78,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Center(
              // The PNGs are flat silhouettes with a baked-in blue tint, so
              // srcIn repaints them in the app's palette and lets the same
              // artwork read on both the filled and idle tile.
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  selected ? Colors.white : AppColors.grey1,
                  BlendMode.srcIn,
                ),
                child: Image.asset(asset, width: 46, height: 46, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.grey3,
              fontSize: 10.5,
              height: 1.25,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
