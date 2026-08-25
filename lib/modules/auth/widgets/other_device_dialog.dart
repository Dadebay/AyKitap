import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/auth_strings.dart';

/// TZ 2.2 — shown when logging in on this device would kick out an
/// existing session elsewhere. Returns true if the user chose to continue.
Future<bool?> showOtherDeviceDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle),
        child: Center(
            child: HugeIcon(
                icon: HugeIcons.strokeRoundedSecurityLock,
                color: AppColors.primary,
                size: 26)),
      ),
      title: Text(
        AuthStrings.otherDeviceTitle,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Text(
        AuthStrings.otherDeviceBody,
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
                    elevation: 0),
                onPressed: () => Navigator.pop(context, true),
                child: Text(AuthStrings.otherDeviceConfirm,
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
                onPressed: () => Navigator.pop(context, false),
                child: Text(AuthStrings.cancel,
                    style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
