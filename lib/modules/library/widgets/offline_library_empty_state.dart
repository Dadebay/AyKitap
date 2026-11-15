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
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: tablet ? 280 : 220,
                height: tablet ? 280 : 220,
                child: Lottie.asset(
                    'assets/animations/no_internet_connection.json',
                    repeat: true,
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 14),
              Text(LibraryStrings.noOfflineBooksTitle,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: tablet ? 20 : 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                LibraryStrings.noOfflineBooksBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: tablet ? 15 : 13,
                    height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
