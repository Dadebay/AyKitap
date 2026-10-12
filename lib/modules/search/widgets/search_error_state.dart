import 'package:flutter/material.dart';

import '../../../core/localization/strings/search_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Search's recoverable request failure with transparent 3D no-connection
/// artwork and the existing retry action.
class SearchErrorState extends StatelessWidget {
  const SearchErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 210),
              child: Image.asset(
                'assets/images/no_connection_dark_transparent.png',
                key: const ValueKey('search-error-3d-image'),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey2,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                SearchStrings.retry,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
