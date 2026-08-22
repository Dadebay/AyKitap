import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Shown in place of the WebView when the book fails to open or render — see
/// `ReaderProvider.loadFailed`. Styled to match the PDF/CBZ readers' own
/// error screens so a bad file looks the same no matter which format it is.
///
/// Unlike [ReaderErrorOverlay] (the PDF/CBZ readers' equivalent), this isn't
/// wrapped in `Positioned.fill` — it replaces the EPUB viewer directly as an
/// ordinary child inside a `Padding`/`SafeArea`, not as an overlay layer
/// inside a `Stack`.
class EpubErrorView extends StatelessWidget {
  final Color bgColor;
  final bool isDarkPage;

  const EpubErrorView(
      {super.key, required this.bgColor, required this.isDarkPage});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedFileNotFound,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ReaderStrings.epubOpenError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkPage ? Colors.white70 : Colors.black54,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
