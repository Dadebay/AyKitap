import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../utils/eye_care.dart';
import 'reader_progress_scrubber.dart';

/// TZ §12.3 — the reader's bottom toolbar: three labelled actions
/// (Mazmun / Sazlamalar / Gözleg) sitting on a gradient bar, above the
/// progress scrubber. The bar floats on a scrim derived from [pageColor]
/// (densest at the bottom, fading up) so it follows the reader theme.
class ReaderBottomBar extends StatelessWidget {
  final double progress;
  final int currentPage;
  final int totalPages;

  /// Background colour of the page underneath (the reader theme's colour).
  final Color pageColor;

  /// Blue-light filter strength (TZ §12.4), 0.0 (off) … 1.0 — tints the
  /// hairline and icon wells the same warm cast as the page overlay. See
  /// [eyeCareTint].
  final double eyeCare;

  final VoidCallback onSettings;
  final VoidCallback onChapters;
  final VoidCallback onSearch;
  final ValueChanged<double> onProgressChanged;

  const ReaderBottomBar({
    super.key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    required this.pageColor,
    this.eyeCare = 0.0,
    required this.onSettings,
    required this.onChapters,
    required this.onSearch,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isDarkPage = pageColor.computeLuminance() < 0.4;
    final labelColor = isDarkPage ? Colors.white38 : Colors.black45;
    // Buttons sit straight on the scrim now (no filled bar), so they take the
    // page's contrast colour like the top bar does.
    final iconColor = isDarkPage ? Colors.white70 : const Color(0xFF44444F);
    final borderColor = eyeCareTint(
      isDarkPage ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
      eyeCare,
      isDarkPage: isDarkPage,
    );
    // The rounded "well" behind each icon — same idiom as the top bar's
    // circular buttons — so taps have an obvious target and feedback.
    final wellColor = eyeCareTint(
      isDarkPage ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
      eyeCare,
      isDarkPage: isDarkPage,
    );
    const accent = Color(0xFFE8712C);

    return Container(
      height: 132 + bottomPad,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            pageColor.withValues(alpha: 0.92),
            pageColor.withValues(alpha: 0.72),
            pageColor.withValues(alpha: 0.28),
            pageColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 0.78, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // A hairline is all that separates the controls from the page now
          // that the filled bar is gone.
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: borderColor,
          ),
          const SizedBox(height: 6),

          // ── Progress scrubber ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ReaderProgressScrubber(
              progress: progress,
              currentPage: currentPage,
              totalPages: totalPages,
              labelColor: labelColor,
              activeColor: accent,
              inactiveTrackColor: isDarkPage ? Colors.white24 : const Color(0xFFE0E0E0),
              overlayColor: const Color(0x22E8712C),
              onSeek: onProgressChanged,
            ),
          ),

          const SizedBox(height: 2),

          // ── Three labelled buttons, straight on the scrim ─────────────
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad + 6),
            child: Row(
              children: [
                // Содержание — chapters list
                _ToolbarBtn(
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  label: ReaderStrings.contentsLabel,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onChapters,
                ),
                // Настройки — reader settings (accented, like the reference)
                _ToolbarBtn(
                  icon: HugeIcons.strokeRoundedFilterHorizontal,
                  label: ReaderStrings.settingsTitle,
                  color: accent,
                  labelColor: accent,
                  wellColor: accent.withValues(alpha: 0.16),
                  onTap: onSettings,
                ),
                // Поиск — in-book search
                _ToolbarBtn(
                  icon: HugeIcons.strokeRoundedSearch01,
                  label: ReaderStrings.searchShortLabel,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onSearch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final Color labelColor;
  final Color wellColor;
  final VoidCallback onTap;

  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.labelColor,
    required this.wellColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                  decoration: BoxDecoration(
                    color: wellColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: FittedBox(child: HugeIcon(icon: icon, color: color, size: 22)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: labelColor, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
