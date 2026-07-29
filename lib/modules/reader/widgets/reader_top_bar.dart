import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icon_circle_button.dart';
import '../utils/eye_care.dart';

/// TZ §12.1 — back on the left, centred chapter title, bookmark toggle on the
/// right.
///
/// The bar has no solid background: it's a scrim that fades from the reading
/// page's own colour at the very top of the screen out to nothing below the
/// buttons. Deriving it from [pageColor] is what makes it follow the reader
/// theme — white on the light theme, near-black on the dark one, sepia on
/// sepia — instead of stamping a black band over a white page.
class ReaderTopBar extends StatelessWidget {
  final String title;
  final bool isBookmarked;

  /// Background colour of the page underneath (the reader theme's colour).
  final Color pageColor;

  /// Blue-light filter strength (TZ §12.4), 0.0 (off) … 1.0 — tints the icon
  /// wells the same warm cast as the page overlay, so the bar doesn't sit on
  /// top of a tinted page as a stray neutral black/white. See [eyeCareTint].
  final double eyeCare;

  final VoidCallback onBack;
  final VoidCallback onBookmark;

  const ReaderTopBar({
    super.key,
    required this.title,
    required this.isBookmarked,
    required this.pageColor,
    this.eyeCare = 0.0,
    required this.onBack,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkPage = pageColor.computeLuminance() < 0.4;
    final fg = isDarkPage ? Colors.white : const Color(0xFF1A1A22);
    final well = eyeCareTint(
      isDarkPage ? Colors.white.withValues(alpha: 0.13) : Colors.black.withValues(alpha: 0.07),
      eyeCare,
      isDarkPage: isDarkPage,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Four stops rather than three: a gentler ramp that never shows a
          // hard edge where the scrim meets the text below it.
          colors: [
            pageColor.withValues(alpha: 0.92),
            pageColor.withValues(alpha: 0.72),
            pageColor.withValues(alpha: 0.28),
            pageColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 0.78, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // The extra bottom inset is the runway the gradient fades over.
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 22),
          child: Row(
            children: [
              IconCircleButton(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                onTap: onBack,
                size: 40,
                iconSize: 19,
                backgroundColor: well,
                iconColor: fg,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 15.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              // HugeIcons ships no filled bookmark, so the marked state reads
              // through the accent colour and a tinted well instead.
              IconCircleButton(
                icon: HugeIcons.strokeRoundedBookmark01,
                onTap: onBookmark,
                size: 40,
                iconSize: 19,
                backgroundColor: isBookmarked ? AppColors.primary.withValues(alpha: 0.20) : well,
                iconColor: isBookmarked ? AppColors.primary : fg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
