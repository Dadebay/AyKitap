import 'package:flutter/material.dart';
import '../../../core/localization/strings/profile_feedback_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [BookRequestSheet]'s submit button + sending spinner — split out to keep
/// that file under the 200-line limit.
class BookRequestSubmitButton extends StatelessWidget {
  final bool sending;
  final VoidCallback? onPressed;

  const BookRequestSubmitButton(
      {super.key, required this.sending, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: sending
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white))
            : Text(ProfileFeedbackStrings.send,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
      ),
    );
  }
}
