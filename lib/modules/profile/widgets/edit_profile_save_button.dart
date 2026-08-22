import 'package:flutter/material.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [EditProfileScreen]'s save button + saving spinner — split out to keep
/// that file under the 200-line limit.
class EditProfileSaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;

  const EditProfileSaveButton(
      {super.key, required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0),
        onPressed: onPressed,
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white))
            : Text(ProfileStrings.save,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700)),
      ),
    );
  }
}
