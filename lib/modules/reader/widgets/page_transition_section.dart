import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_provider.dart';
import 'page_transition_sheet.dart';
import 'transition_meta.dart';

export 'page_transition_sheet.dart';

/// TZ §12.2 — the "Sahypa çalyşmak" row inside [ReaderSettingsSheet]. Rather
/// than expanding inline, it opens [PageTransitionSheet] as its own modal —
/// each settings group gets its own popup, matching the reference design.
class PageTransitionRow extends StatelessWidget {
  const PageTransitionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        return Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeftRight,
                      color: AppColors.primary,
                      size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ReaderStrings.pageTransitionTitle,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(transitionLabel(provider.pageTransition),
                      style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppColors.grey3, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const PageTransitionSheet(),
      ),
    );
  }
}
