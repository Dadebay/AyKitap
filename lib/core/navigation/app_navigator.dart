import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import 'fade_page_route.dart';
import 'hero_page_route.dart';

/// Kills the `Navigator.push(context, MaterialPageRoute(builder: (_) => X()))`
/// boilerplate repeated at every call site — this is a plain `MaterialPageRoute`
/// push, nothing more.
extension AppNavigator on BuildContext {
  Future<T?> push<T>(Widget screen) =>
      Navigator.push<T>(this, MaterialPageRoute(builder: (_) => screen));

  /// For a push whose destination shares a [Hero] with this screen — see
  /// [HeroPageRoute] for why those don't take the platform page transition.
  Future<T?> pushHero<T>(Widget screen) => Navigator.push<T>(
        this,
        HeroPageRoute<T>(
            child: screen, reduceMotion: AppMotion.reduceMotion(this)),
      );

  /// For a push with no shared cover to carry over — a banner tap, a deep
  /// link — where the platform's own zoom/slide transition would be the only
  /// alternative. A short fade instead of either that or a fake [Hero].
  Future<T?> pushFade<T>(Widget screen) => Navigator.push<T>(
        this,
        FadePageRoute<T>(
            child: screen, reduceMotion: AppMotion.reduceMotion(this)),
      );

  void pop<T>([T? result]) => Navigator.pop(this, result);
}
