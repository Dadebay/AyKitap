import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/subscription_service.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/localization/strings/payment_strings.dart';
import 'widgets/plan_card.dart';

/// Töleg Ulgamy — TZ section 13.1 (abunalyk planlary). Promo kod we bank
/// kartasy bilen balans doldurmak indi FinanceScreen-de (Profil > Maliýe).
/// Confirming a plan really debits the balance and activates
/// [SubscriptionService] — once active, [BookDetailScreen] shows "Oka" for
/// every book instead of gating each one behind [BookPurchaseScreen].
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static List<Plan> get _plans => [
        Plan(type: SubscriptionPlanType.weekly, name: PaymentStrings.planWeekly),
        Plan(type: SubscriptionPlanType.monthly, name: PaymentStrings.planMonthly, best: true),
        Plan(type: SubscriptionPlanType.threeMonths, name: PaymentStrings.plan3Months),
        Plan(type: SubscriptionPlanType.sixMonths, name: PaymentStrings.plan6Months),
      ];

  int _selected = 1;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.load();
  }

  Future<void> _subscribe() async {
    if (_processing) return;
    setState(() => _processing = true);
    final plan = _plans[_selected];
    final ok = await SubscriptionService.instance.subscribe(plan.type);
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? PaymentStrings.subscriptionActivated(plan.name) : PaymentStrings.balanceNotEnough),
        backgroundColor: ok ? AppColors.primary : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = context.watch<SubscriptionService>().expiresAt;
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
                ..._plans.asMap().entries.map((entry) {
                  final i = entry.key;
                  final plan = entry.value;
                  final selected = _selected == i;
                  return PlanCard(
                    plan: plan,
                    selected: selected,
                    onTap: () {
                      if (selected) return;
                      HapticFeedback.selectionClick();
                      setState(() => _selected = i);
                    },
                  );
                }),
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
                onPressed: _processing ? null : _subscribe,
                child: _processing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                    : Text(
                        expiresAt != null ? '${PaymentStrings.renew} — ${PaymentStrings.manat(_plans[_selected].priceManat)}' : PaymentStrings.subscribeWithPrice(_plans[_selected].priceManat),
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
}
