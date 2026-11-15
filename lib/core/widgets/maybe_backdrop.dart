import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../services/device_tier.dart';

/// [BackdropFilter] blur that is skipped on low-end phones, where each blur
/// forces an offscreen buffer and is one of the costliest things to paint.
/// The child (a tinted container) still draws, so the panel stays readable.
class MaybeBackdrop extends StatelessWidget {
  final double sigma;
  final Widget child;
  const MaybeBackdrop({super.key, required this.sigma, required this.child});

  @override
  Widget build(BuildContext context) {
    if (DeviceTier.isLowEnd) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
