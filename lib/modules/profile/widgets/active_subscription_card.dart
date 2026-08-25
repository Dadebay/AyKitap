import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/theme_controller.dart';

/// Premium treatment for a server-confirmed active subscription. This is
/// intentionally not a regular profile entry card: an active entitlement is
/// useful account status, not another settings row, and deserves hierarchy.
class ActiveSubscriptionCard extends StatefulWidget {
  const ActiveSubscriptionCard({
    super.key,
    required this.expiresAt,
    required this.onTap,
  });

  final DateTime expiresAt;
  final VoidCallback onTap;

  @override
  State<ActiveSubscriptionCard> createState() => _ActiveSubscriptionCardState();
}

class _ActiveSubscriptionCardState extends State<ActiveSubscriptionCard> {
  bool _pressed = false;

  int get _daysLeft {
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 0;
    final minutesPerDay = Duration.hoursPerDay * Duration.minutesPerHour;
    final days = (remaining.inMinutes / minutesPerDay).ceil();
    if (days < 1) return 1;
    return days > 9999 ? 9999 : days;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    final titleColor =
        isDark ? const Color(0xFFF9F5FF) : const Color(0xFF2A2031);
    final mutedColor =
        isDark ? const Color(0xFFC9BDD4) : const Color(0xFF706477);
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.075)
        : Colors.white.withValues(alpha: 0.72);
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF241B30), Color(0xFF30203C), Color(0xFF211C35)]
          : const [Color(0xFFFFF5EC), Color(0xFFFFEEF5), Color(0xFFF1EBFF)],
    );

    return Semantics(
      button: true,
      label:
          '${ProfileStrings.subscription}, ${ProfileStrings.subscriptionActiveStatus}',
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              gradient: AppGradients.journeyPrimary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? const Color(0xFF9C3FCC)
                          : const Color(0xFFB34BEA))
                      .withValues(alpha: isDark ? 0.18 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.8),
              child: Stack(
                children: [
                  Positioned.fill(
                      child: DecoratedBox(
                          decoration: BoxDecoration(gradient: cardGradient))),
                  Positioned(
                    right: -44,
                    top: -52,
                    child: _GlowOrb(
                      size: 138,
                      color: const Color(0xFFB34BEA)
                          .withValues(alpha: isDark ? 0.16 : 0.12),
                    ),
                  ),
                  Positioned(
                    left: -32,
                    bottom: -54,
                    child: _GlowOrb(
                      size: 116,
                      color: const Color(0xFFFF8A4C)
                          .withValues(alpha: isDark ? 0.12 : 0.10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppGradients.journeyPrimary,
                                borderRadius: BorderRadius.circular(17),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5C7D)
                                        .withValues(alpha: 0.24),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedDiamond,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aýkitap Plus',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ProfileStrings.subscriptionAllBooksUnlocked,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C985)
                                    .withValues(alpha: isDark ? 0.16 : 0.13),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFF34C985)
                                      .withValues(alpha: 0.34),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 14, color: Color(0xFF28B978)),
                                  const SizedBox(width: 5),
                                  Text(
                                    ProfileStrings.subscriptionActiveStatus,
                                    style: const TextStyle(
                                      color: Color(0xFF28B978),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Expanded(
                              child: _SubscriptionMetric(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                label: ProfileStrings.subscriptionExpiryLabel,
                                value:
                                    DateFormat.yMMMd().format(widget.expiresAt),
                                foreground: titleColor,
                                muted: mutedColor,
                                background: surfaceColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SubscriptionMetric(
                                icon: HugeIcons.strokeRoundedClock01,
                                label: ProfileStrings.subscription,
                                value: ProfileStrings.subscriptionDaysLeft(
                                    _daysLeft),
                                foreground: titleColor,
                                muted: mutedColor,
                                background: surfaceColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback:
                                  AppGradients.journeyPrimary.createShader,
                              child: Text(
                                ProfileStrings.subscriptionManage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: isDark
                                  ? const Color(0xFFD9C9EB)
                                  : const Color(0xFF7C568E),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionMetric extends StatelessWidget {
  const _SubscriptionMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.foreground,
    required this.muted,
    required this.background,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color foreground;
  final Color muted;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: const Color(0xFFC552A8), size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: muted, fontSize: 9.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: foreground,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
