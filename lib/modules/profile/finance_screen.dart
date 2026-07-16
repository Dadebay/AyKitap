import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/streak_service.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../payment/subscription_screen.dart';

/// Standalone "Maliýe" (finance) page — TZ 8.2: promo code redemption,
/// current balance, and bank-card top-up — pushed as its own route rather
/// than living inline on the Profile tab.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceManat = context.watch<StreakService>().balanceManat;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        centerTitle: true,
        title: Text(ProfileStrings.finance, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ProfileStrings.balance, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.push(const SubscriptionScreen()),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedCreditCard, color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(ProfileStrings.balanceManat(balanceManat), style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                          child: TextField(
                            controller: _promoController,
                            style: TextStyle(color: AppColors.white, fontSize: 13.5),
                            decoration: InputDecoration(hintText: ProfileStrings.promoCodeHint, hintStyle: TextStyle(color: AppColors.grey3), border: InputBorder.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          onPressed: () => context.showAppSnackBar(ProfileStrings.promoCheckingMock),
                          child: Text(ProfileStrings.use, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => context.push(const SubscriptionScreen()),
                      child: Text(ProfileStrings.topUpWithCard, style: TextStyle(color: AppColors.grey1, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
