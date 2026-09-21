import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/payment_strings.dart';
import '../../core/models/tariff.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/payment_api_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import 'payment_webview_screen.dart';
import 'subscription_plan_helpers.dart';
import 'widgets/bank_select_sheet.dart';
import 'widgets/insufficient_balance_dialog.dart';
import 'widgets/payment_method_sheet.dart';
import 'widgets/promo_code_sheet.dart';
import 'widgets/subscription_checkout_button.dart';
import 'widgets/subscription_header.dart';
import 'widgets/subscription_plan_list.dart';
import 'widgets/subscription_success_dialog.dart';

part 'subscription_screen_actions.dart';

/// Töleg Ulgamy — TZ section 13.1 (abunalyk planlary). Plans come from
/// `GET /payments/tariffs` ([PaymentApiService.getTariffs]). Tapping the
/// bottom button pays for the plan straight from the balance
/// ([SubscriptionService.subscribe] → `POST /users/buy-subscription/:id`) —
/// no "how do you want to pay" step in between. If the balance is short, a
/// dialog explains the shortfall and, on "Töle", falls back to
/// [PaymentMethodSheet] (promo code, or a bank-card top-up for exactly the
/// plan's price — [BankSelectSheet] + [PaymentWebViewScreen] — that then
/// retries the purchase). Once active, [BookDetailScreen] shows "Oka" for
/// every book instead of gating each one behind [BookPurchaseScreen].
///
/// The payment-flow methods ([_startCheckout] and everything it can lead
/// to) live in subscription_screen_actions.dart, a `part` of this file, to
/// keep this file under the 200-line limit.
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
    unawaited(AnalyticsService.instance.logPaywallViewed(
      source: 'subscription_screen',
    ));
    context.read<SubscriptionService>().load();
    _loadTariffs();
  }

  // setState is @protected — the payment-action methods in
  // subscription_screen_actions.dart live in an extension, not a subclass,
  // so they call this thin wrapper instead of setState directly.
  void _setState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final expiresAt = context.watch<SubscriptionService>().expiresAt;
    final tariffs = _tariffs;
    final hasSelection = tariffs != null && tariffs.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.journeyMist,
      appBar: AppBar(
        backgroundColor: AppColors.journeyMist,
        leading: const AppBackButton(size: 20),
        centerTitle: true,
        title: Text(PaymentStrings.subscriptionTitle,
            style: TextStyle(
                color: AppColors.journeyInk,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                children: [
                  SubscriptionHeader(expiresAt: expiresAt),
                  const SizedBox(height: 30),
                  Text(
                    PaymentStrings.chooseYourPlan,
                    style: TextStyle(
                      color: AppColors.journeyInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PaymentStrings.chooseYourPlanSubtitle,
                    style: TextStyle(
                      color: AppColors.grey2,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SubscriptionPlanList(
                    loading: _loading,
                    error: _error,
                    tariffs: tariffs ?? const [],
                    selected: _selected,
                    onRetry: _loadTariffs,
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                ],
              ),
            ),
            SubscriptionCheckoutButton(
              processing: _processing,
              hasSelection: hasSelection,
              expiresAt: expiresAt,
              selectedTariff: hasSelection ? tariffs[_selected] : null,
              onPressed: _startCheckout,
            ),
          ],
        ),
      ),
    );
  }
}
