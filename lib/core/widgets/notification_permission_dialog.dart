import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../localization/strings/notification_strings.dart';
import '../theme/app_colors.dart';

/// The in-app explanation shown once before the native permission prompt.
///
/// Pops true when the user opts in, false for "Häzir däl", and null if it was
/// dismissed — [NotificationPermissionFlow] treats the last two the same.
/// Deliberately dismissible: this isn't a decision the app should trap
/// someone in.
Future<bool?> showNotificationPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedNotification02,
            color: AppColors.primary,
            size: 26,
          ),
        ),
      ),
      title: Text(
        NotificationStrings.promptTitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        NotificationStrings.promptBody,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      actions: [
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  NotificationStrings.promptAllow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  NotificationStrings.promptNotNow,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
