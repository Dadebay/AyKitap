import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../core/services/account_service.dart';
import '../../core/services/revenue_cat_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../payment/balance_top_up.dart';
import 'provider/balance_controller.dart';
import 'widgets/balance_card.dart';
import 'widgets/balance_card_payments_list.dart';
import 'widgets/balance_history_list.dart';
import 'widgets/balance_history_tab_toggle.dart';

/// "Balansym" — the full balance page reached from the profile's balance
/// entry row. Leads with the same [BalanceCard] (amount + "Doldur") the
/// profile screen used to show inline, then the user's top-up and purchase
/// history below.
class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BalanceController()..load(),
      child: const _BalanceView(),
    );
  }
}

class _BalanceView extends StatefulWidget {
  const _BalanceView();

  @override
  State<_BalanceView> createState() => _BalanceViewState();
}

class _BalanceViewState extends State<_BalanceView> {
  BalanceTab _selectedTab = BalanceTab.history;
  late final Future<bool> _storeTopUpAvailability;

  @override
  void initState() {
    super.initState();
    // The Doldur CTA needs this same region/payment-mode request. Start it
    // while the balance page is becoming visible so a likely tap does not
    // wait for a second round trip. Errors intentionally resolve to false:
    // the normal wallet flow remains available without showing any message.
    _storeTopUpAvailability = RevenueCatApiService.getConfig()
        .then((config) => config.isStoreIap)
        .catchError((_) => false);
  }

  Future<void> _openTopUp() async {
    await startBalanceTopUp(
      context,
      storeTopUpAvailability: _storeTopUpAvailability,
    );
    if (!mounted) return;
    context.read<BalanceController>().load();
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
        title: Text(ProfileStrings.balanceTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            BalanceCard(balanceManat: balance, onTopUp: _openTopUp),
            const SizedBox(height: 20),
            BalanceHistoryTabToggle(
              selected: _selectedTab,
              historyLabel: ProfileStrings.balanceHistoryTitle,
              cardPaymentsLabel: ProfileStrings.cardPaymentsTitle,
              onChanged: (tab) => setState(() => _selectedTab = tab),
            ),
            const SizedBox(height: 16),
            _selectedTab == BalanceTab.history
                ? const BalanceHistoryList()
                : const BalanceCardPaymentsList(),
          ],
        ),
      ),
    );
  }
}
