import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/account_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../payment/balance_top_up.dart';
import 'widgets/balance_card.dart';

/// "Balansym" — the full balance page reached from the profile's balance
/// entry row. Leads with the same [BalanceCard] (amount + "Doldur") the
/// profile screen used to show inline, then a top-up history list below.
///
/// MISSING BACKEND: there is no top-up-history endpoint yet, so the history
/// section always renders the themed empty state — swap it for a real list
/// once that endpoint exists.
class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  Future<void> _openTopUp() async {
    await startBalanceTopUp(context);
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<AccountService>().balanceManat;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(ProfileStrings.balanceTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            BalanceCard(balanceManat: balance, onTopUp: _openTopUp),
            const SizedBox(height: 28),
            Text(
              ProfileStrings.balanceHistoryTitle,
              style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _buildHistoryEmpty(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEmpty() {
    final isDark = AppTheme.instance.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                isDark ? 'assets/images/balance_empty_dark.png' : 'assets/images/balance_empty_light.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ProfileStrings.balanceHistoryEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            ProfileStrings.balanceHistoryEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
