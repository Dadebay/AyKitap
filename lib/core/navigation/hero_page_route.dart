import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// The route to push a screen that receives a [Hero] from the screen below.
///
/// [MaterialPageRoute] uses the platform's own page transition — on Android a
/// zoom that scales and fades the whole incoming page while scaling the
/// outgoing one away. A cover flying its own straight path over that reads as
/// two unrelated motions happening at once, which is what made the shelf →
/// detail transition feel wrong however the flight itself was tuned.
///
/// Here the page only fades. The cover is the one thing that moves, so the
/// eye follows it instead of splitting between it and a zooming backdrop.
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  HeroPageRoute({
    required Widget child,
    required bool reduceMotion,
  }) : super(
          transitionDuration:
              reduceMotion ? AppMotion.instant : AppMotion.heroFlight,
          reverseTransitionDuration:
              reduceMotion ? AppMotion.instant : AppMotion.standard,
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (_, animation, __, page) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              // Settled well before the flight lands at 1.0: the cover has to
              // touch down on a page that is already fully opaque, or it
              // would appear to fade up in place after arriving.
              curve: const Interval(0, 0.7, curve: AppMotion.easeOut),
            ),
            child: page,
          ),
        );
}
