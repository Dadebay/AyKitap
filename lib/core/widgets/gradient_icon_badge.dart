import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../constants/app_radius.dart';
import '../theme/app_gradients.dart';

/// The square gradient icon badge shown at the top of the auth screens
/// (phone login, OTP, name entry) — was copy-pasted at each call site.
class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = 64,
    this.gradient = AppGradients.coralPurple,
  });

  final List<List<dynamic>> icon;
  final double size;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(gradient: gradient, borderRadius: AppRadius.brXl),
      child: Center(
          child: HugeIcon(icon: icon, color: Colors.white, size: size * 0.47)),
    );
  }
}
