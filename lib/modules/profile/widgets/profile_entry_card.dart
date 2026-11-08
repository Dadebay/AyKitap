import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

/// A tinted circular icon badge, used as the leading visual on every
/// profile entry card so they all read as one family.
Widget profileIconCircle(List<List<dynamic>> icon, {Color? color}) {
  final c = color ?? AppColors.primary;
  return Container(
    width: 40,
    height: 40,
    decoration:
        BoxDecoration(color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
    child: Center(child: HugeIcon(icon: icon, color: c, size: 20)),
  );
}

/// Shared shell for every row on the Profile tab (subscription, streak,
/// finance, settings, notes, book request) so they share one padding,
/// radius, and title/subtitle typography instead of each drifting apart.
class ProfileEntryCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final bool highlighted;

  /// A distinct accent for a row that needs its own identity rather than the
  /// shared orange [highlighted] treatment — e.g. the subscription row's
  /// rose-violet tint (TZ S5). When set, this entirely replaces the
  /// [highlighted] rendering (a thin left-edge gradient bar plus a matching
  /// title/wash colour drawn from the gradient's own first stop) rather than
  /// combining with it, so a caller passes one or the other, never both.
  ///
  /// [highlighted] alone is untouched by this — every existing call site
  /// (the book-request CTA) keeps the exact orange look it always had.
  final LinearGradient? accentGradient;
  final VoidCallback onTap;

  const ProfileEntryCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.extra,
    this.highlighted = false,
    this.accentGradient,
    required this.onTap,
  });

  /// Corner radius for every entry card — 18dp sits mid-range of the 16-20dp
  /// spec (TZ S5), a touch airier than the previous flat 16 without being a
  /// visibly different shape.
  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    if (accentGradient != null) return _buildAccented(context, accentGradient!);

    final titleColor = highlighted ? AppColors.primary : AppColors.grey1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.card,
          borderRadius: BorderRadius.circular(_radius),
          border: highlighted
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: _content(titleColor),
      ),
    );
  }

  /// The [accentGradient] path: a slim gradient bar down the card's left edge
  /// over a faint two-colour gradient wash — a deliberately quieter "this row
  /// is distinct" cue ("ince vurgu", TZ S5) than the [highlighted] path's flat
  /// tinted background+border, while still visibly a *gradient* fill (not a
  /// flat colour) so it reads as the same family as [JourneyGradientIconBadge]
  /// sitting next to it.
  ///
  /// Built with [Stack]/[Positioned] rather than a [Row] with
  /// `CrossAxisAlignment.stretch`: a stretch-aligned Row sizes its cross axis
  /// from its *non-flexible* children first — and the bar (a bare
  /// [Container] with only a width, no height of its own) has zero natural
  /// height, so the whole row collapsed to a zero-height, untappable card
  /// with nothing below it able to lay out either. A [Stack] sizes itself
  /// from the real (non-positioned) content first, and only then stretches
  /// the [Positioned] bar to match — no such ordering trap.
  Widget _buildAccented(BuildContext context, LinearGradient gradient) {
    // The gradient's own leading stop as a flat colour for the title — both
    // [AppGradients] gradients used here already return their light/dark
    // build from the same getter, so this needs no theme branching of its
    // own.
    final accentColor = gradient.colors.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // The card's own fill: the accent gradient itself, heavily
            // faded — a wash, not the saturated badge/bar colour.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      for (final c in gradient.colors) c.withValues(alpha: 0.10)
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: _content(accentColor),
            ),
            // The full-strength bar, on top of the wash and the content's
            // own padding, pinned to the left edge.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradient.colors,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: AppColors.grey2,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: highlighted || accentGradient != null
                    ? titleColor
                    : AppColors.grey3,
                size: 18),
          ],
        ),
        if (extra != null) ...[
          const SizedBox(height: 14),
          extra!,
        ],
      ],
    );
  }
}
