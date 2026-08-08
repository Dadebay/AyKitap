import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/payment_strings.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../core/models/balance_log.dart';
import '../../core/models/payment_order.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/balance_log_api_service.dart';
import '../../core/services/payment_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_back_button.dart';
import '../payment/balance_top_up.dart';
import 'widgets/balance_card.dart';

/// "Balansym" — the full balance page reached from the profile's balance
/// entry row. Leads with the same [BalanceCard] (amount + "Doldur") the
/// profile screen used to show inline, then the user's top-up and purchase
/// history below.
class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  _BalanceTab _selectedTab = _BalanceTab.history;
  List<BalanceLog>? _logs;
  String? _error;
  // Best-effort, separate from [_logs]/[_error] — a failure here shouldn't
  // block the (more important) balance history above it, so this section
  // just quietly stays empty rather than showing its own error state.
  List<PaymentOrder>? _orders;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadOrders();
  }

  Future<void> _loadLogs() async {
    setState(() => _error = null);
    try {
      final logs = await BalanceLogApiService.listLogs();
      if (!mounted) return;
      setState(() => _logs = logs);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await PaymentApiService.getMyOrders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } on ApiException {
      // See the field's doc comment — silently leave the section empty.
      if (mounted) setState(() => _orders = const []);
    }
  }

  Future<void> _openTopUp() async {
    await startBalanceTopUp(context);
    if (!mounted) return;
    _loadLogs();
    _loadOrders();
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
    if (_orders == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_orders!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_off_rounded, color: AppColors.grey2, size: 36),
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
      itemCount: _orders!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _PaymentOrderTile(order: _orders![index]),
    );
  }

  Widget _buildHistory() {
    if (_logs == null && _error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: TextButton(
            onPressed: _loadLogs,
            child: Text(ProfileStrings.retry,
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }
    final logs = _logs!;
    if (logs.isEmpty) return _buildHistoryEmpty();
    return RefreshIndicator(
      onRefresh: _loadLogs,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _BalanceLogTile(log: logs[index]),
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
                    ? 'assets/images/balance_empty_dark.png'
                    : 'assets/images/balance_empty_light.png',
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

class _BalanceLogTile extends StatelessWidget {
  const _BalanceLogTile({required this.log});

  final BalanceLog log;

  @override
  Widget build(BuildContext context) {
    final isPurchase = log.isBookPurchase;
    final color =
        isPurchase ? const Color(0xFFE65C5C) : const Color(0xFF3FBE6C);
    final title = isPurchase
        ? (log.bookName?.isNotEmpty == true
            ? log.bookName!
            : ProfileStrings.balanceBookPurchase)
        : log.event.toUpperCase().contains('DEPOSIT') ||
                log.event.toUpperCase().contains('PROMO')
            ? ProfileStrings.balanceTopUp
            : ProfileStrings.balanceOtherActivity;
    final subtitle = isPurchase
        ? ProfileStrings.balanceBookPurchase
        : log.event.replaceAll('_', ' ');
    final displayedAmount = log.amount.abs();
    final amountPrefix = log.isCredit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, color.withValues(alpha: 0.075)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Icon(
                  isPurchase ? Icons.menu_book_rounded : Icons.savings_rounded,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$amountPrefix${PaymentStrings.manat(displayedAmount)}',
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Divider(
                height: 1, color: AppColors.border.withValues(alpha: 0.75)),
          ),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: AppColors.grey2),
              const SizedBox(width: 6),
              Text(
                DateFormat.yMMMd().add_Hm().format(log.createdAt),
                style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(
                log.isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 15,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOrderTile extends StatelessWidget {
  const _PaymentOrderTile({required this.order});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context) {
    final logo = order.bank.logoAsset;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: logo != null
                ? Image.asset(logo, fit: BoxFit.cover)
                : Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBank, color: AppColors.grey2, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.bank.name, style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  DateFormat.yMMMd().add_Hm().format(order.createdAt),
                  style: TextStyle(color: AppColors.grey2, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(PaymentStrings.manat(order.amount), style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
