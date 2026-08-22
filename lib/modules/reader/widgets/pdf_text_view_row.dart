import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// The reverse of the EPUB reader's "view original PDF pages" row: offered
/// in [PdfSettingsSheet] once a text-layer conversion for this book already
/// exists in cache, for a reader who forced fixed page images and wants the
/// reflowable view back.
class PdfTextViewRow extends StatelessWidget {
  final VoidCallback onTap;
  const PdfTextViewRow({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  color: AppColors.primary,
                  size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReaderStrings.pdfTextViewLabel,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ReaderStrings.pdfTextViewHint,
                      style: TextStyle(color: AppColors.grey2, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.grey3, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
