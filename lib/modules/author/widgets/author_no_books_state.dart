import 'package:flutter/material.dart';
import '../../../core/localization/strings/author_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// [CatalogAuthorDetailScreen]'s empty state — shown when the author has no
/// books in the catalogue.
class AuthorNoBooksState extends StatelessWidget {
  const AuthorNoBooksState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(
              isDark
                  ? 'assets/images/author_no_books_dark.webp'
                  : 'assets/images/author_no_books_light.webp',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AuthorStrings.noBooksYetTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          AuthorStrings.noBooksYetSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.4),
        ),
      ],
    );
  }
}
