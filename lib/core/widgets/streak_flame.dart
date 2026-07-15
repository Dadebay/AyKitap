import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// The looping streak flame (Lottie). Kept small and always animating so the
/// streak counter draws the eye. Reused in the home header and the profile.
class StreakFlame extends StatelessWidget {
  final double size;
  const StreakFlame({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/streak.json',
        repeat: true,
        fit: BoxFit.contain,
      ),
    );
  }
}
