import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A thin rule–label–rule divider ("or") splitting two sign-in paths —
/// phone/OTP vs. Google/Apple/email on the auth screens. Generic enough for
/// any "either this or that" split, not auth-specific itself.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: TextStyle(
                  color: AppColors.grey3,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
