import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';

/// The wallet card at the top of Profile — the balance from `/users/me`
/// ([AccountService]) plus the "Doldur" action that starts a top-up.
///
/// Deliberately not a [ProfileEntryCard]: the amount is the point here, so
/// it gets its own display-sized treatment and an explicit button rather
/// than the shared row's title/subtitle/chevron shape.
class BalanceCard extends StatelessWidget {
  /// Null while `/users/me` hasn't answered yet — renders a placeholder
  /// instead of a misleading "0 manat".
  final int? balanceManat;
  final VoidCallback onTopUp;

  const BalanceCard(
      {super.key, required this.balanceManat, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    final balance = balanceManat;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Center(
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedWallet01,
                        color: Colors.white,
                        size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProfileStrings.balanceTitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ProfileStrings.balanceSubtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: balance == null
                    ? SizedBox(
                        height: 30,
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 80,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        PaymentStrings.manat(balance),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1),
                      ),
              ),
              GestureDetector(
                onTap: onTopUp,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          color: AppColors.primary,
                          size: 16),
                      const SizedBox(width: 6),
                      Text(
                        ProfileStrings.topUpBalance,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
