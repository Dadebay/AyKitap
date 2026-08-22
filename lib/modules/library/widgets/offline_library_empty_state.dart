import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [OfflineLibraryScreen]'s empty state — shown when the user has no
/// on-device (imported) books to open offline.
class OfflineLibraryEmptyState extends StatelessWidget {
  const OfflineLibraryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                  'assets/animations/no_internet_connection.json',
                  repeat: true,
                  fit: BoxFit.contain),
            ),
            const SizedBox(height: 14),
            Text(LibraryStrings.noOfflineBooksTitle,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              LibraryStrings.noOfflineBooksBody,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
