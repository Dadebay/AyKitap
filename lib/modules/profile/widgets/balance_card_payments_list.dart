import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/balance_controller.dart';
import 'balance_history_tiles.dart';

/// [BalanceScreen]'s "Kart arkaly tölegler" tab body.
class BalanceCardPaymentsList extends StatelessWidget {
  const BalanceCardPaymentsList({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<BalanceController>().orders;
    if (orders == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_off_rounded,
                color: AppColors.grey2, size: 36),
            const SizedBox(height: 12),
            Text(
              ProfileStrings.cardPaymentsEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              ProfileStrings.cardPaymentsEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey2, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => PaymentOrderTile(order: orders[index]),
    );
  }
}
