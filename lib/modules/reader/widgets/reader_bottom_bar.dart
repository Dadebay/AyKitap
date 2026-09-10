import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../utils/eye_care.dart';
import 'reader_progress_scrubber.dart';
import 'reader_toolbar_btn.dart';

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
    // The readers can be rotated (see reader_orientation.dart); everything
    // below keys off this rather than a width breakpoint, since it's the lost
    // *height* that the bar has to give back to the page.
    final compact = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDarkPage = pageColor.computeLuminance() < 0.4;
    final labelColor = isDarkPage ? Colors.white38 : Colors.black45;
    // Buttons sit straight on the scrim now (no filled bar), so they take the
    // page's contrast colour like the top bar does.
    final iconColor = isDarkPage ? Colors.white70 : const Color(0xFF44444F);
    final borderColor = eyeCareTint(
      isDarkPage
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.08),
      eyeCare,
      isDarkPage: isDarkPage,
    );
    // The rounded "well" behind each icon — same idiom as the top bar's
    // circular buttons — so taps have an obvious target and feedback.
    final wellColor = eyeCareTint(
      isDarkPage
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
      eyeCare,
      isDarkPage: isDarkPage,
    );
    const accent = Color(0xFFE8712C);

    return Container(
      // Rotated, the screen is barely half as tall (~390dp), and the portrait
      // bar's 132dp would eat a third of it before a line of the book is
      // drawn. The compact variant drops the button captions — the three icons
      // are the same ones, in the same order, and there's no room for a page
      // of text *and* a caption — which buys the page back ~36dp.
      height: (compact ? 96 : 132) + bottomPad,
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
              // Reflowable text has no fixed pages, so the derived count
              // shifts between sessions — see ReaderProgressScrubber. The
              // percentage is the figure that actually holds still.
              showPercentage: true,
              labelColor: labelColor,
              activeColor: accent,
              inactiveTrackColor:
                  isDarkPage ? Colors.white24 : const Color(0xFFE0E0E0),
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
                ReaderToolbarBtn(
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  label: ReaderStrings.contentsLabel,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onChapters,
                  compact: compact,
                ),
                // Настройки — reader settings (accented, like the reference)
                ReaderToolbarBtn(
                  icon: HugeIcons.strokeRoundedFilterHorizontal,
                  label: ReaderStrings.settingsTitle,
                  color: accent,
                  labelColor: accent,
                  wellColor: accent.withValues(alpha: 0.16),
                  onTap: onSettings,
                  compact: compact,
                ),
                // Поиск — in-book search
                ReaderToolbarBtn(
                  icon: HugeIcons.strokeRoundedSearch01,
                  label: ReaderStrings.searchShortLabel,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onSearch,
                  compact: compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
