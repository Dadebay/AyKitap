import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_continue_strings.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/last_read_book_store.dart' show LastReadBook;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';

/// The "Continue reading" card on [ReaderTabScreen] — cover, title, resume
/// page and a play button, all tapping through to [openLastReadBook].
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard(
      {super.key, required this.book, required this.onTap});

  final LastReadBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final page = book.page + 1;
    final pageLabel = book.pageCount == null
        ? ReaderContinueStrings.resumeAtPage(page)
        : ReaderContinueStrings.resumeAtPageOf(page, book.pageCount!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReaderContinueStrings.continueReading,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 76,
                      height: 112,
                      child: book.image == null || book.image!.isEmpty
                          ? _coverPlaceholder()
                          : NetworkCoverImage(
                              url: ApiConfig.resolveImageUrl(book.image!),
                              placeholder: (_) => _coverPlaceholder(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pageLabel,
                          style: TextStyle(
                            color: AppColors.grey2,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedPlay,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ReaderContinueStrings.continueReading,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        color: AppColors.surface,
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedBook02,
            color: AppColors.grey2,
            size: 28,
          ),
        ),
      );
}
