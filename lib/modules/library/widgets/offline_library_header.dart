import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/theme/app_colors.dart';

/// The "no internet" banner row at the top of [OfflineLibraryScreen].
class OfflineLibraryHeader extends StatelessWidget {
  const OfflineLibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.grey3.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Center(
                child: HugeIcon(
                    icon: HugeIcons.strokeRoundedWifiDisconnected01,
                    color: AppColors.grey2,
                    size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LibraryStrings.noInternetTitle,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(LibraryStrings.noInternetSubtitle,
                    style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
