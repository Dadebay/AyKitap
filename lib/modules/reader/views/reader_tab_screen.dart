import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// "Continue reading" quick-access tab. Shows the last opened book, or an
/// empty state if nothing has been started yet.
class ReaderTabScreen extends StatelessWidget {
  const ReaderTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey2, size: 34),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                ReaderStrings.noBookYetTitle,
                style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                ReaderStrings.noBookYetSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
