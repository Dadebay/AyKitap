import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

class LibraryEmptyState extends StatelessWidget {
  final String label;
  final String? sub;
  const LibraryEmptyState({super.key, required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  isDark ? 'assets/images/library_empty_dark.png' : 'assets/images/library_empty_light.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 15)),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(sub!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey3, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
