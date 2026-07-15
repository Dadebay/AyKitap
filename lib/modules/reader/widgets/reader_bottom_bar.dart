import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ReaderBottomBar extends StatelessWidget {
  final double progress;
  final int currentPage;
  final int totalPages;
  final VoidCallback onSettings;
  final VoidCallback onChapters;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final ValueChanged<double> onProgressChanged;

  const ReaderBottomBar({
    super.key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    required this.onSettings,
    required this.onChapters,
    required this.onBookmark,
    required this.onShare,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 90 + bottomPad,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ── Pill container ────────────────────────────────────────────
          Positioned(
            bottom: bottomPad,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        '$currentPage',
                        style: const TextStyle(color: Colors.black45, fontSize: 11),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: const Color(0xFFE8712C),
                            inactiveTrackColor: const Color(0xFFE0E0E0),
                            thumbColor: const Color(0xFFE8712C),
                            overlayColor: Color(0x22E8712C),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: onProgressChanged,
                          ),
                        ),
                      ),
                      Text(
                        '$totalPages',
                        style: const TextStyle(color: Colors.black45, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 2),

                // Pill bar
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Chapters
                      _PillBtn(
                        icon: HugeIcons.strokeRoundedMenu01,
                        onTap: onChapters,
                      ),
                      // Bookmark
                      _PillBtn(
                        icon: HugeIcons.strokeRoundedBookmark01,
                        onTap: onBookmark,
                      ),

                      // Center gap
                      const SizedBox(width: 56),

                      // Share
                      _PillBtn(
                        icon: HugeIcons.strokeRoundedShare01,
                        onTap: onShare,
                      ),
                      // Settings
                      _PillBtn(
                        icon: HugeIcons.strokeRoundedSettings01,
                        onTap: onSettings,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating center button (font / Aa) ────────────────────────
          Positioned(
            bottom: bottomPad + 6,
            child: GestureDetector(
              onTap: onSettings,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8712C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8712C).withValues(alpha: 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  const _PillBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: HugeIcon(icon: icon, color: const Color(0xFF888899), size: 22),
        ),
      ),
    );
  }
}
