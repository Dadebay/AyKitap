import 'package:flutter/material.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// [NotesScreen]'s empty state — shown when the signed-in account has no
/// saved notes/highlights yet.
class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({super.key});

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
              constraints: const BoxConstraints(maxWidth: 260),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  isDark
                      ? 'assets/images/notes_empty_dark.webp'
                      : 'assets/images/notes_empty_light.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              ProfileStrings.noNotesYetTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              ProfileStrings.noNotesYetSubtitle,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
