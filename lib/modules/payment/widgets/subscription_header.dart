import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/theme_controller.dart';

/// Premium hero for the subscription screen. Active entitlement information
/// shares the Plus hierarchy instead of looking like a detached warning row.
class SubscriptionHeader extends StatelessWidget {
  const SubscriptionHeader({super.key, required this.expiresAt});

  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final expiry = expiresAt;
    final isDark = AppTheme.instance.isDark;
    final foreground =
        isDark ? const Color(0xFFF9F5FF) : const Color(0xFF281F30);
    final muted = isDark ? const Color(0xFFCABFD4) : const Color(0xFF716578);
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF251B31), Color(0xFF34203F), Color(0xFF211D36)]
          : const [Color(0xFFFFF4EA), Color(0xFFFFEDF5), Color(0xFFF0E9FF)],
    );

    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: AppGradients.journeyPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFB34BEA).withValues(alpha: isDark ? 0.16 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.8),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: cardGradient),
              ),
            ),
            Positioned(
              right: -56,
              top: -64,
              child: _Orb(
                size: 170,
                color: const Color(0xFFB34BEA).withValues(alpha: 0.13),
              ),
            ),
            Positioned(
              left: -44,
              bottom: -70,
              child: _Orb(
                size: 148,
                color: const Color(0xFFFF8A4C).withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppGradients.journeyPrimary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5C7D)
                                  .withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/logo.webp',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aýkitap Plus',
                              style: TextStyle(
                                color: foreground,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PaymentStrings.unlimitedAccessTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (expiry != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C985)
                                .withValues(alpha: isDark ? 0.16 : 0.13),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF34C985)
                                  .withValues(alpha: 0.34),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF28B978),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    PaymentStrings.unlimitedAccessSubtitle,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _BenefitChip(
                        icon: HugeIcons.strokeRoundedBookOpen01,
                        label: PaymentStrings.benefitAllBooks,
                        foreground: foreground,
                        isDark: isDark,
                      ),
                      _BenefitChip(
                        icon: HugeIcons.strokeRoundedDiamond,
                        label: PaymentStrings.benefitNoExtraPurchase,
                        foreground: foreground,
                        isDark: isDark,
                      ),
                      _BenefitChip(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        label: PaymentStrings.benefitKeepProgress,
                        foreground: foreground,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  if (expiry != null) ...[
                    const SizedBox(height: 17),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.075)
                            : Colors.white.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            color: Color(0xFFC552A8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              PaymentStrings.activeUntil(
                                DateFormat.yMMMd().format(expiry),
                              ),
                              style: TextStyle(
                                color: foreground,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.isDark,
  });

  final List<List<dynamic>> icon;
  final String label;
  final Color foreground;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.075)
              : Colors.white.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: const Color(0xFFC552A8), size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
