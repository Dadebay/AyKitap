import 'package:flutter/material.dart';

import '../../../core/localization/strings/onboarding_strings.dart';
import '../../../core/theme/app_gradients.dart';

/// iPad layout for the sign-in screens: a brand panel on the left and the
/// form on the right, instead of the phone's single column floating in the
/// middle of a wide, empty screen. On a phone (under 700dp) it is just
/// [child], so those screens are unchanged.
class AuthTabletShell extends StatelessWidget {
  const AuthTabletShell({super.key, required this.child});

  /// The form — the screen's existing scrollable content.
  final Widget child;

  static const _breakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < _breakpoint) return child;
    return Row(
      children: [
        const Expanded(flex: 5, child: _BrandPanel()),
        Expanded(flex: 4, child: child),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.coralPurple),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft rings behind the content, purely decorative.
          Positioned(
            top: -120,
            left: -120,
            child: _ring(380, 0.10),
          ),
          Positioned(
            bottom: -160,
            right: -100,
            child: _ring(480, 0.08),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset('assets/images/logo.webp',
                        width: 104, height: 104, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 32),
                  const Text('Aýkitap',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          height: 1.1)),
                  const SizedBox(height: 20),
                  Text(OnboardingStrings.page1Title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.25)),
                  const SizedBox(height: 14),
                  // Some translations carry a literal `\` where a line break was meant.
                  Text(OnboardingStrings.page1Subtitle.replaceAll(r'\', '\n'),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 17,
                          height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: alpha), width: 56),
        ),
      );
}
