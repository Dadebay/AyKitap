import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// Size presets for [JourneyGradientIconBadge] — diameter and the icon size
/// that reads cleanly inside it. Matching [IconCircleButton]'s 40/20 default
/// scale rather than inventing a new one, so a Journey badge sits comfortably
/// next to the app's existing icon buttons.
enum JourneyBadgeSize { small, medium, large }

/// * [pastel]: the default — a soft [AppGradients.journeySoft] disc with a
///   single contrasting icon colour on top. For routine rows (balance,
///   settings, notes) where the icon should read clearly but not compete for
///   attention.
/// * [primaryAction]: no filled disc — the icon glyph itself is painted with
///   the [AppGradients.journeyPrimary] sweep via [ShaderMask]. Reserved for
///   the one action on a screen that should carry the full accent, since a
///   page of these would just be noise; see the task doc's "yalnız
///   gerektiğinde" (only when it's actually called for).
enum JourneyBadgeVariant { pastel, primaryAction }

/// A reusable circular badge for the Journey visual language (S3's tokens) —
/// wraps a plain [Icon] or [HugeIcon] and recolors/resizes it through
/// [IconTheme], so the caller never sets a colour or size on the icon itself
/// and can't end up fighting the badge for either.
///
/// Deliberately static: no [AnimationController], press animation, glow or
/// pulse. A caller that wants those wraps this widget from the outside — this
/// one just answers "what does the badge look like at rest".
///
/// Both icon paths stay vector at every size — [HugeIcon] renders its own SVG
/// string and Flutter's [Icon] is a font glyph — so a [small] badge is exactly
/// as sharp as a [large] one; nothing here rasterizes or scales a bitmap.
class JourneyGradientIconBadge extends StatelessWidget {
  const JourneyGradientIconBadge({
    super.key,
    required this.icon,
    this.size = JourneyBadgeSize.medium,
    this.variant = JourneyBadgeVariant.pastel,
    this.semanticsLabel,
    this.iconColor,
    this.gradient,
  });

  /// A bare [Icon] or [HugeIcon] — pass it without its own `color`/`size` so
  /// this badge's [IconTheme] governs both.
  final Widget icon;

  final JourneyBadgeSize size;
  final JourneyBadgeVariant variant;

  /// Read by a screen reader in place of the icon's own (usually absent)
  /// semantics — e.g. "Balance", "Subscription". Omit for a purely
  /// decorative badge that already sits next to its own visible label.
  final String? semanticsLabel;

  /// [pastel] only: overrides the default contrasting icon colour
  /// ([AppColors.journeyInk]). Has no effect on [primaryAction] — there the
  /// glyph is repainted by [gradient] regardless of its own colour.
  final Color? iconColor;

  /// Overrides the variant's default gradient ([AppGradients.journeySoft] for
  /// [pastel], [AppGradients.journeyPrimary] for [primaryAction]) — e.g. for a
  /// badge that should carry [AppGradients.journeySunset] instead.
  final LinearGradient? gradient;

  double get _diameter => switch (size) {
        JourneyBadgeSize.small => 32,
        JourneyBadgeSize.medium => 48,
        JourneyBadgeSize.large => 64,
      };

  double get _iconSize => switch (size) {
        JourneyBadgeSize.small => 16,
        JourneyBadgeSize.medium => 22,
        JourneyBadgeSize.large => 30,
      };

  @override
  Widget build(BuildContext context) {
    final content = switch (variant) {
      JourneyBadgeVariant.pastel => _PastelBadge(
          diameter: _diameter,
          iconSize: _iconSize,
          iconColor: iconColor ?? AppColors.journeyInk,
          gradient: gradient ?? AppGradients.journeySoft,
          child: icon,
        ),
      JourneyBadgeVariant.primaryAction => _PrimaryActionBadge(
          diameter: _diameter,
          iconSize: _iconSize,
          gradient: gradient ?? AppGradients.journeyPrimary,
          child: icon,
        ),
    };

    if (semanticsLabel == null) return content;
    // excludeSemantics: true — the icon underneath is decorative (an Icon/
    // HugeIcon carries no semantics of its own anyway) and without it a
    // screen reader could see both this label and whatever the icon exposes.
    return Semantics(label: semanticsLabel, excludeSemantics: true, child: content);
  }
}

class _PastelBadge extends StatelessWidget {
  const _PastelBadge({
    required this.diameter,
    required this.iconSize,
    required this.iconColor,
    required this.gradient,
    required this.child,
  });

  final double diameter;
  final double iconSize;
  final Color iconColor;
  final LinearGradient gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
      child: IconTheme(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: child,
      ),
    );
  }
}

class _PrimaryActionBadge extends StatelessWidget {
  const _PrimaryActionBadge({
    required this.diameter,
    required this.iconSize,
    required this.gradient,
    required this.child,
  });

  final double diameter;
  final double iconSize;
  final LinearGradient gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Center(
        // ShaderMask paints `gradient` wherever the child draws opaque
        // pixels (BlendMode.srcIn) — the child's own colour underneath is
        // irrelevant as long as it's opaque, so IconThemeData.color here is
        // just "any solid colour", not the badge's real colour.
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: IconTheme(
            data: IconThemeData(color: Colors.white, size: iconSize),
            child: child,
          ),
        ),
      ),
    );
  }
}
