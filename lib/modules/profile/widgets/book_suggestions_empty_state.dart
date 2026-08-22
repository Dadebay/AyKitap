import 'package:flutter/material.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// [BookSuggestionsScreen]'s empty state — shown while the signed-in
/// account has never sent a book request.
class BookSuggestionsEmptyState extends StatelessWidget {
  const BookSuggestionsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  isDark
                      ? 'assets/images/book_request_empty_dark.webp'
                      : 'assets/images/book_request_empty_light.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              ProfileStrings.noSuggestionsYet,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.grey2, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
