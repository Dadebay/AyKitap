import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// A shared full-page state for a timed-out or unavailable internet
/// connection. The artwork follows the app theme and the primary action
/// keeps retrying obvious without relying on a small text link.
class NetworkErrorState extends StatelessWidget {
  const NetworkErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return ColoredBox(
      color: isDark ? const Color(0xFF0A0A0B) : AppColors.bg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Image.asset(
                  isDark
                      ? 'assets/images/no_connection_dark.webp'
                      : 'assets/images/no_connection_light.webp',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Internet baglanyşygy ýok',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Internet baglanyşygyňyzy barlap, gaýtadan synanyşyň.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey2, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Gaýtadan synanyş'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
