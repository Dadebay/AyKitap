import 'package:flutter/material.dart';
import '../constants/app_radius.dart';
import '../theme/app_colors.dart';

/// The full-width, 56px-tall primary action button repeated across auth,
/// payment, and profile screens — orange when enabled, card-colored and
/// disabled otherwise, with a spinner swapped in while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 56.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _enabled ? AppColors.primary : AppColors.card,
          disabledBackgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
          elevation: 0,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white))
            : Text(
                label,
                style: TextStyle(
                    color: _enabled ? Colors.white : AppColors.grey3,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
