import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// The "view original PDF pages" row — same card shape as the page-transition
/// row but a one-shot action rather than a row that opens a submenu: tapping
/// it pops the whole settings sheet with `true`, which [ReaderScreen] reads
/// to swap over to [PdfReaderScreen].
class ReaderOriginalPdfRow extends StatelessWidget {
  final VoidCallback onTap;
  const ReaderOriginalPdfRow({super.key, required this.onTap});

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
                  icon: HugeIcons.strokeRoundedFile02,
                  color: AppColors.primary,
                  size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReaderStrings.pdfOriginalViewLabel,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ReaderStrings.pdfOriginalViewHint,
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
