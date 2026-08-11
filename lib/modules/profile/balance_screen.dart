import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../core/services/account_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_back_button.dart';
import '../payment/balance_top_up.dart';
import 'provider/balance_controller.dart';
import 'widgets/balance_card.dart';
import 'widgets/balance_history_tiles.dart';

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
  _BalanceTab _selectedTab = _BalanceTab.history;

  Future<void> _openTopUp() async {
    await startBalanceTopUp(context);
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
            _buildHistoryTabToggle(),
            const SizedBox(height: 16),
            _selectedTab == _BalanceTab.history
                ? _buildHistory()
                : _buildCardPayments(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTabToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = (constraints.maxWidth - 12) / 2;
        return CupertinoSlidingSegmentedControl<_BalanceTab>(
          groupValue: _selectedTab,
          backgroundColor: AppColors.card,
          thumbColor: AppColors.primary,
          padding: const EdgeInsets.all(3),
          onValueChanged: (tab) {
            if (tab != null && tab != _selectedTab) {
              setState(() => _selectedTab = tab);
            }
          },
          children: {
            _BalanceTab.history: _tabLabel(
              ProfileStrings.balanceHistoryTitle,
              _BalanceTab.history,
              segmentWidth,
            ),
            _BalanceTab.cardPayments: _tabLabel(
              ProfileStrings.cardPaymentsTitle,
              _BalanceTab.cardPayments,
              segmentWidth,
            ),
          },
        );
      },
    );
  }

  Widget _tabLabel(String label, _BalanceTab tab, double width) {
    final selected = _selectedTab == tab;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.grey2,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardPayments() {
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
                fontWeight: FontWeight.w700,
              ),
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

  Widget _buildHistory() {
    final controller = context.watch<BalanceController>();
    if (controller.logs == null && controller.error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: TextButton(
            onPressed: controller.loadLogs,
            child: Text(ProfileStrings.retry,
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }
    final logs = controller.logs!;
    if (logs.isEmpty) return _buildHistoryEmpty();
    return RefreshIndicator(
      onRefresh: controller.loadLogs,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, index) => BalanceLogTile(log: logs[index]),
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
                isDark
                    ? 'assets/images/balance_empty_dark.webp'
                    : 'assets/images/balance_empty_light.webp',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ProfileStrings.balanceHistoryEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            ProfileStrings.balanceHistoryEmptySubtitle,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}

enum _BalanceTab { history, cardPayments }
