import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// The PDF reader's bottom toolbar, built to the same design as the EPUB
/// [ReaderBottomBar]: a scrim derived from the page colour (densest at the
/// bottom, fading up), a hairline, the page scrubber, then three labelled
/// actions sitting in rounded "wells".
///
/// The actions differ from the EPUB bar because a fixed-layout page can't
/// answer the same questions: there's no table of contents to list and no text
/// to search, so those slots go to the things a PDF *can* do — its bookmarks,
/// and jumping to an exact page (the scrubber alone is too coarse on a
/// 300-page book).
class PdfBottomBar extends StatelessWidget {
  final double progress;
  final int currentPage;
  final int totalPages;

  /// Background colour of the page underneath, so the bar follows the reader's
  /// light/dark gutter the way the EPUB bar follows the page theme.
  final Color pageColor;

  final VoidCallback onBookmarks;
  final VoidCallback onSettings;
  final VoidCallback onGoToPage;
  final ValueChanged<double> onProgressChanged;

  const PdfBottomBar({
    super.key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    required this.pageColor,
    required this.onBookmarks,
    required this.onSettings,
    required this.onGoToPage,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isDarkPage = pageColor.computeLuminance() < 0.4;
    final labelColor = isDarkPage ? Colors.white38 : Colors.black45;
    final iconColor = isDarkPage ? Colors.white70 : const Color(0xFF44444F);
    final borderColor = isDarkPage ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);
    final wellColor = isDarkPage ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
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
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20), color: borderColor),
          const SizedBox(height: 6),

          // ── Page scrubber ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('$currentPage', style: TextStyle(color: labelColor, fontSize: 11)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: accent,
                      inactiveTrackColor: isDarkPage ? Colors.white24 : const Color(0xFFE0E0E0),
                      thumbColor: accent,
                      overlayColor: const Color(0x22E8712C),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: onProgressChanged,
                    ),
                  ),
                ),
                Text('$totalPages', style: TextStyle(color: labelColor, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 2),

          // ── Three labelled actions ────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad + 6),
            child: Row(
              children: [
                _PdfToolbarBtn(
                  icon: HugeIcons.strokeRoundedBookmark02,
                  label: ReaderStrings.bookmarksTitle,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onBookmarks,
                ),
                // Accented, matching the EPUB bar where settings is the
                // primary action of the three.
                _PdfToolbarBtn(
                  icon: HugeIcons.strokeRoundedFilterHorizontal,
                  label: ReaderStrings.settingsTitle,
                  color: accent,
                  labelColor: accent,
                  wellColor: accent.withValues(alpha: 0.16),
                  onTap: onSettings,
                ),
                _PdfToolbarBtn(
                  icon: HugeIcons.strokeRoundedGridView,
                  label: ReaderStrings.pdfGoToPageShort,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onGoToPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfToolbarBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final Color labelColor;
  final Color wellColor;
  final VoidCallback onTap;

  const _PdfToolbarBtn({
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
