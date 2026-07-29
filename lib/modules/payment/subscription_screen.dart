import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/models/tariff.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/payment_api_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/payment_strings.dart';
import 'payment_webview_screen.dart';
import 'widgets/bank_select_sheet.dart';
import 'widgets/payment_method_sheet.dart';
import 'widgets/plan_card.dart';
import 'widgets/promo_code_sheet.dart';

/// Töleg Ulgamy — TZ section 13.1 (abunalyk planlary). Plans come from
/// `GET /payments/tariffs` ([PaymentApiService.getTariffs]). Tapping the
/// bottom button debits the plan's price straight from the balance
/// ([SubscriptionService.subscribe] → [AccountService.debitBalance]) — no
/// "how do you want to pay" step in between. If the balance is short, a
/// dialog explains the shortfall and, on "Töle", falls back to
/// [PaymentMethodSheet] (promo code or the real bank-card checkout —
/// [BankSelectSheet] + [PaymentWebViewScreen]) to actually get the money in.
/// Once active, [BookDetailScreen] shows "Oka" for every book instead of
/// gating each one behind [BookPurchaseScreen].
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<Tariff>? _tariffs;
  bool _loading = true;
  String? _error;
  int _selected = 0;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.load();
    _loadTariffs();
  }

  Future<void> _loadTariffs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tariffs = await PaymentApiService.getTariffs();
      if (!mounted) return;
      setState(() {
        _tariffs = tariffs;
        _loading = false;
        // Default to the best-value plan (biggest discount) rather than
        // always the 2nd one — with a dynamic tariff list there's no fixed
        // "monthly is always index 1" to lean on anymore.
        _selected = _bestIndex(tariffs);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  static int _bestIndex(List<Tariff> tariffs) {
    var best = 0;
    for (var i = 1; i < tariffs.length; i++) {
      if (tariffs[i].discountPercent > tariffs[best].discountPercent) best = i;
    }
    return best;
  }

  static String _labelFor(Tariff tariff) {
    switch (tariff.monthCount) {
      case 1:
        return PaymentStrings.planMonthly;
      case 3:
        return PaymentStrings.plan3Months;
      case 6:
        return PaymentStrings.plan6Months;
      case 12:
        return PaymentStrings.planYearly;
      default:
        return PaymentStrings.planMonthsGeneric(tariff.monthCount);
    }
  }

  Future<void> _startCheckout() async {
    final tariffs = _tariffs;
    if (_processing || tariffs == null || tariffs.isEmpty) return;
    final tariff = tariffs[_selected];

    setState(() => _processing = true);
    final ok = await SubscriptionService.instance.subscribe(monthCount: tariff.monthCount, priceManat: tariff.price);
    if (!mounted) return;
    setState(() => _processing = false);

    if (ok) {
      context.showAppSnackBar(PaymentStrings.subscriptionActivated(_labelFor(tariff)));
    } else {
      await _showInsufficientBalanceDialog();
    }
  }

  /// Shown when [SubscriptionService.subscribe] can't debit the plan's price
  /// from the balance — explains the shortfall with the themed empty-state
  /// illustration and, on "Töle", hands off to [PaymentMethodSheet] so the
  /// user can pick promo code vs. bank card rather than always landing on
  /// the bank flow.
  Future<void> _showInsufficientBalanceDialog() async {
    final isDark = AppTheme.instance.isDark;
    final pay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Image.asset(
                isDark ? 'assets/images/balance_empty_dark.png' : 'assets/images/balance_empty_light.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              PaymentStrings.balanceNotEnough,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              PaymentStrings.subscriptionBalanceInsufficientNote,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              onPressed: () => Navigator.pop(context, true),
              child: Text(PaymentStrings.payNow, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(PaymentStrings.close, style: TextStyle(color: AppColors.grey2, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
    if (pay == true && mounted) await _choosePaymentMethod();
  }

  Future<void> _choosePaymentMethod() async {
    final choice = await PaymentMethodSheet.show(context);
    if (choice == null || !mounted) return;
    switch (choice) {
      case PaymentMethodChoice.promoCode:
        await _payWithPromoCode();
      case PaymentMethodChoice.bankCard:
        await _payWithBank();
    }
  }

  /// Redeems the code via `POST /users/promo-codes` — the backend credits
  /// the balance, not the plan directly, so this just refreshes
  /// [AccountService] and then re-runs the normal balance-funded checkout
  /// (which now might actually cover the price).
  Future<void> _payWithPromoCode() async {
    final code = await PromoCodeSheet.show(context);
    if (code == null || code.isEmpty || !mounted) return;

    setState(() => _processing = true);
    try {
      await AuthApiService.redeemPromoCode(code: code);
      await AccountService.instance.refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      context.showAppSnackBar(e.message, isError: true);
      return;
    }
    if (!mounted) return;
    setState(() => _processing = false);
    context.showAppSnackBar(PaymentStrings.promoCodeAppliedBalance);
    await _startCheckout();
  }

  Future<void> _payWithBank() async {
    final tariffs = _tariffs;
    if (_processing || tariffs == null || tariffs.isEmpty) return;
    final bank = await BankSelectSheet.show(context);
    if (bank == null || !mounted) return;

    setState(() => _processing = true);
    final tariff = tariffs[_selected];
    try {
      final url = await PaymentApiService.initiateSubscriptionPayment(tariffId: tariff.id, bankId: bank.id);
      if (!mounted) return;
      setState(() => _processing = false);
      if (url == null || url.isEmpty) {
        context.showAppSnackBar(PaymentStrings.paymentUrlError, isError: true);
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: url)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = context.watch<SubscriptionService>().expiresAt;
    final tariffs = _tariffs;
    final hasSelection = tariffs != null && tariffs.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        centerTitle: true,
        title: Text(PaymentStrings.subscriptionTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedDiamond, color: AppColors.primary, size: 28)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        PaymentStrings.unlimitedAccessTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        PaymentStrings.unlimitedAccessSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                  if (expiresAt != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(PaymentStrings.activeSubscription, style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                                Text(PaymentStrings.activeUntil(DateFormat.yMMMd().format(expiresAt)), style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ..._buildPlanList(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  onPressed: (_processing || !hasSelection) ? null : _startCheckout,
                  child: _processing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                      : Text(
                          !hasSelection
                              ? PaymentStrings.subscriptionTitle
                              : expiresAt != null
                                  ? '${PaymentStrings.renew} — ${PaymentStrings.manat(tariffs[_selected].price)}'
                                  : PaymentStrings.subscribeWithPrice(tariffs[_selected].price),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlanList() {
    if (_loading) {
      return [Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(PaymentStrings.tariffsLoadError, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 8),
              TextButton(onPressed: _loadTariffs, child: Text(PaymentStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      ];
    }
    final tariffs = _tariffs ?? const [];
    final bestIndex = tariffs.isEmpty ? -1 : _bestIndex(tariffs);
    return tariffs.asMap().entries.map((entry) {
      final i = entry.key;
      final tariff = entry.value;
      final selected = _selected == i;
      return PlanCard(
        tariff: tariff,
        label: _labelFor(tariff),
        best: i == bestIndex && tariff.discountPercent > 0,
        selected: selected,
        onTap: () {
          if (selected) return;
          HapticFeedback.selectionClick();
          setState(() => _selected = i);
        },
      );
    }).toList();
  }
}
