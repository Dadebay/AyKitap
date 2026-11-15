import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_continue_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [ReaderTabScreen]'s empty state — shown while there's no resumable last-
/// read book (never opened one, the file is gone, or access has lapsed).
class ReaderEmptyState extends StatelessWidget {
  const ReaderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    return Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: tablet ? 112 : 84,
                    height: tablet ? 112 : 84,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedBook02,
                        color: AppColors.grey2,
                        size: tablet ? 46 : 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    ReaderContinueStrings.noBookYetTitle,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: tablet ? 21 : 17,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ReaderContinueStrings.noBookYetSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.grey2,
                        fontSize: tablet ? 16 : 14,
                        height: 1.5),
                  ),
                ],
              ))),
    );
  }
}
