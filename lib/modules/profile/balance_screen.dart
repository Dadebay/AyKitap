import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../core/services/account_service.dart';
import '../../core/services/purchase_mode_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../payment/balance_top_up.dart';
import '../payment/open_subscription_screen.dart';
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
    // wait for a second round trip. [PurchaseModeService.refresh] never
    // throws — on iOS a failed request still leaves useStoreCheckout `true`
    // rather than opening the promo/bank flow.
    _storeTopUpAvailability = PurchaseModeService.instance
        .refresh()
        .then((_) => PurchaseModeService.instance.useStoreCheckout);
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
    // Balance can't buy anything on iOS while the App Store review toggle
    // is on (no single-book purchase, subscriptions bought directly through
    // the store) — see APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md and
    // [BalanceCard.useSubscribeCta]. Sending the user to "Doldur" there
    // would load money onto a balance with nothing left to spend it on.
    final iosStoreOnly = context.watch<PurchaseModeService>().isIOSStoreOnly;
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
            BalanceCard(
              balanceManat: balance,
              useSubscribeCta: iosStoreOnly,
              onAction: iosStoreOnly
                  ? () => openSubscriptionScreen(context)
                  : _openTopUp,
            ),
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
