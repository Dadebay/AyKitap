import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

class LibraryEmptyState extends StatelessWidget {
  final String label;
  final String? sub;
  const LibraryEmptyState({super.key, required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedLibrary, color: AppColors.grey3, size: 56),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: AppColors.grey2, fontSize: 15)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey3, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
