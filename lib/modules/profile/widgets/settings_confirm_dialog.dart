import 'package:flutter/material.dart';
import '../../../core/localization/strings/settings_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Centred icon, title, body and a stacked primary/cancel action pair —
/// [SettingsScreen]'s logout and "delete account" confirmations share this
/// exact shape, differing only in colour, icon, copy and what the primary
/// action does.
Future<void> showSettingsConfirmDialog(
  BuildContext context, {
  required Widget icon,
  required double iconSize,
  required Color iconColor,
  required String title,
  required String body,
  required String confirmLabel,
  required Color confirmColor,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Center(child: icon),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Text(
        body,
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
                    backgroundColor: confirmColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                onPressed: onConfirm,
                child: Text(confirmLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(SettingsStrings.cancel,
                    style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
