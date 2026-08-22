import 'package:flutter/material.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Recoverable state for Home's two server-driven data sources. Keeping this
/// inside the scroll view means the header remains visible while the reader
/// retries, rather than presenting an abruptly blank full-page error.
class HomeReloadState extends StatelessWidget {
  const HomeReloadState(
      {super.key, required this.loading, required this.onReload});

  final bool loading;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 128),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded,
                    color: AppColors.primary, size: 27),
              ),
              const SizedBox(height: 16),
              Text(
                HomeStrings.reloadTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                HomeStrings.reloadBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey2, fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onReload,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(HomeStrings.reload),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.65),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
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
