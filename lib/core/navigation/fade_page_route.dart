import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// A push with no [Hero] to carry — a banner tap, a deep link, anything that
/// lands on [CatalogBookDetailScreen] without a shelf card underneath it to
/// fly a cover from. A plain, short fade instead of either the platform's
/// page transition or a fake/mismatched [Hero].
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({required Widget child, required bool reduceMotion})
      : super(
          transitionDuration:
              reduceMotion ? AppMotion.instant : AppMotion.linkFade,
          reverseTransitionDuration:
              reduceMotion ? AppMotion.instant : AppMotion.linkFade,
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (_, animation, __, page) => FadeTransition(
            opacity:
                CurvedAnimation(parent: animation, curve: AppMotion.easeOut),
            child: page,
          ),
        );
}
