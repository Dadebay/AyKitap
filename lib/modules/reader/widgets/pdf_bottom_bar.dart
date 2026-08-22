import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/localization/strings/reader_notes_strings.dart';
import '../../../core/localization/strings/reader_bookmark_strings.dart';
import '../utils/eye_care.dart';
import 'reader_progress_scrubber.dart';
import 'reader_toolbar_btn.dart';

/// The PDF reader's bottom toolbar, built to the same design as the EPUB
/// [ReaderBottomBar]: a scrim derived from the page colour (densest at the
/// bottom, fading up), a hairline, the page scrubber, then three labelled
/// actions sitting in rounded "wells".
///
/// The actions differ from the EPUB bar because a fixed-layout page can't
/// answer the same questions: there's no table of contents to list and no text
/// to search, so those slots go to the things a PDF *can* do — its bookmarks,
/// a page-anchored note (see [showAddPageNoteSheet]), and jumping to an exact
/// page (the scrubber alone is too coarse on a 300-page book).
///
/// Four actions rather than the EPUB bar's three, so the captions are the
/// first thing to go when there isn't room — that's what [compact] already
/// does in landscape.
class PdfBottomBar extends StatelessWidget {
  final double progress;
  final int currentPage;
  final int totalPages;

  /// Background colour of the page underneath, so the bar follows the reader's
  /// light/dark gutter the way the EPUB bar follows the page theme.
  final Color pageColor;

  /// Blue-light filter strength (TZ §12.4), 0.0 (off) … 1.0 — tints the
  /// hairline and icon wells the same warm cast as the page overlay. See
  /// [eyeCareTint].
  final double eyeCare;

  final VoidCallback onBookmarks;
  final VoidCallback onAddNote;
  final VoidCallback onSettings;
  final VoidCallback onGoToPage;
  final ValueChanged<double> onProgressChanged;

  const PdfBottomBar({
    super.key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    required this.pageColor,
    this.eyeCare = 0.0,
    required this.onBookmarks,
    required this.onAddNote,
    required this.onSettings,
    required this.onGoToPage,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // Landscape reading (see reader_orientation.dart) — same compaction as
    // [ReaderBottomBar], so both readers' bars shrink identically.
    final compact = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDarkPage = pageColor.computeLuminance() < 0.4;
    final labelColor = isDarkPage ? Colors.white38 : Colors.black45;
    final iconColor = isDarkPage ? Colors.white70 : const Color(0xFF44444F);
    final borderColor = eyeCareTint(
      isDarkPage
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.08),
      eyeCare,
      isDarkPage: isDarkPage,
    );
    final wellColor = eyeCareTint(
      isDarkPage
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
      eyeCare,
      isDarkPage: isDarkPage,
    );
    const accent = Color(0xFFE8712C);

    return Container(
      // See [ReaderBottomBar]: rotated, 132dp would take a third of the
      // screen, so the captions go and the bar gives ~36dp back to the page.
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
          Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: borderColor),
          const SizedBox(height: 6),

          // ── Page scrubber ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ReaderProgressScrubber(
              progress: progress,
              currentPage: currentPage,
              totalPages: totalPages,
              labelColor: labelColor,
              activeColor: accent,
              inactiveTrackColor:
                  isDarkPage ? Colors.white24 : const Color(0xFFE0E0E0),
              overlayColor: const Color(0x22E8712C),
              onSeek: onProgressChanged,
            ),
          ),

          const SizedBox(height: 2),

          // ── Four labelled actions ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad + 6),
            child: Row(
              children: [
                ReaderToolbarBtn(
                  icon: HugeIcons.strokeRoundedBookmark02,
                  label: ReaderBookmarkStrings.bookmarksTitle,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onBookmarks,
                  compact: compact,
                ),
                // The EPUB reader hangs "Not" off a text selection; there is
                // no selection to hang it off here, so it lives in the bar.
                ReaderToolbarBtn(
                  icon: HugeIcons.strokeRoundedNoteAdd,
                  label: ReaderNotesStrings.noteLabel,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onAddNote,
                  compact: compact,
                ),
                // Accented, matching the EPUB bar where settings is the
                // primary action.
                ReaderToolbarBtn(
                  icon: HugeIcons.strokeRoundedFilterHorizontal,
                  label: ReaderStrings.settingsTitle,
                  color: accent,
                  labelColor: accent,
                  wellColor: accent.withValues(alpha: 0.16),
                  onTap: onSettings,
                  compact: compact,
                ),
                ReaderToolbarBtn(
                  icon: HugeIcons.strokeRoundedGridView,
                  label: ReaderStrings.pdfGoToPageShort,
                  color: iconColor,
                  labelColor: labelColor,
                  wellColor: wellColor,
                  onTap: onGoToPage,
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
