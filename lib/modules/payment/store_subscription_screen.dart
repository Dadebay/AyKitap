import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/strings/payment_strings.dart';
import '../../core/localization/strings/settings_strings.dart';
import '../../core/models/contact_info.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/contact_api_service.dart';
import '../../core/services/revenue_cat_api_service.dart';
import '../../core/services/revenue_cat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import 'widgets/store_plan_card.dart';
import 'widgets/subscription_header.dart';
import 'widgets/subscription_success_dialog.dart';

/// The App Store/Play Store subscription screen — same visual language as
/// [SubscriptionScreen] (TMT/balance), but buys the real store subscription
/// through RevenueCat directly instead of debiting the backend balance.
/// Replaces RevenueCat's native Paywall Builder screen as the entry point
/// from [SettingsScreen] so plan copy, colors and layout stay under our own
/// control (hot-reloadable, no dashboard editing) while still going through
/// actual App Store/Play billing — see [RevenueCatService.purchasePackage],
/// built for exactly this "custom plan-picker" case.
class StoreSubscriptionScreen extends StatefulWidget {
  const StoreSubscriptionScreen({super.key});

  @override
  State<StoreSubscriptionScreen> createState() =>
      _StoreSubscriptionScreenState();
}

class _StoreSubscriptionScreenState extends State<StoreSubscriptionScreen> {
  List<Package>? _packages;
  bool _loading = true;
  String? _error;
  int _selected = 0;
  bool _processing = false;
  bool _restoring = false;
  ContactInfo? _contact;

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.instance
        .logPaywallViewed(source: 'store_subscription_screen'));
    _loadPackages();
    _loadContact();
  }

  // Apple App Review requires a working Privacy Policy and Terms of
  // Use/EULA link next to the purchase CTA (see
  // APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md §5.5) — reuses the same `/contacts`
  // links [ContactUsSheet] already shows elsewhere in the app rather than a
  // second, possibly-diverging copy. Silent on failure: this is a secondary
  // row, not worth blocking or erroring the whole paywall over.
  Future<void> _loadContact() async {
    try {
      final contact = await ContactApiService.getContacts();
      if (mounted) setState(() => _contact = contact);
    } catch (_) {
      // Left null — the links row just doesn't render (see _buildLegalLinks).
    }
  }

  Future<void> _openLink(String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      context.showAppSnackBar(SettingsStrings.contactLinkOpenError,
          isError: true);
    }
  }

  Future<void> _loadPackages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final offerings = await context.read<RevenueCatService>().getOfferings();
    final all = offerings?.current?.availablePackages ?? const <Package>[];
    // Yearly first — it's the plan worth defaulting to, same as the TMT
    // screen's [bestSubscriptionPlanIndex].
    final packages = [...all]..sort((a, b) {
        int rank(Package p) => switch (p.packageType) {
              PackageType.annual => 0,
              PackageType.monthly => 1,
              _ => 2,
            };
        return rank(a).compareTo(rank(b));
      });
    if (!mounted) return;
    setState(() {
      _packages = packages;
      _loading = false;
      _selected = 0;
      _error = packages.isEmpty ? PaymentStrings.storePlansUnavailable : null;
    });
  }

  Future<void> _startCheckout() async {
    final packages = _packages;
    if (_processing || packages == null || packages.isEmpty) return;
    final package = packages[_selected];
    final revenueCat = context.read<RevenueCatService>();

    unawaited(AnalyticsService.instance.logPurchaseStep(
      step: 'started',
      productType: 'subscription',
      productId: package.storeProduct.identifier,
      source: 'store',
      value: package.storeProduct.price,
    ));
    setState(() => _processing = true);
    try {
      final info = await revenueCat.purchasePackage(package);
      if (!mounted) return;
      setState(() => _processing = false);
      if (info == null) {
        // User cancelled — not an error, nothing to log as a failure.
        unawaited(AnalyticsService.instance.logPurchaseStep(
          step: 'cancelled',
          productType: 'subscription',
          productId: package.storeProduct.identifier,
          source: 'store',
          value: package.storeProduct.price,
        ));
        return;
      }
      try {
        await RevenueCatApiService.reconcile();
      } catch (_) {
        // Best-effort — the webhook still credits the entitlement on its own.
      }
      if (!mounted || !revenueCat.isPlusActive) return;
      unawaited(AnalyticsService.instance.logPurchaseStep(
        step: 'completed',
        productType: 'subscription',
        productId: package.storeProduct.identifier,
        source: 'store',
        value: package.storeProduct.price,
      ));
      await SubscriptionSuccessDialog.show(context, PaymentStrings.plusPlanName);
      if (mounted) Navigator.of(context).pop();
    } on RevenueCatPurchaseException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      unawaited(AnalyticsService.instance.logPurchaseStep(
        step: 'failed',
        productType: 'subscription',
        productId: package.storeProduct.identifier,
        source: 'store',
        value: package.storeProduct.price,
      ));
      context.showAppSnackBar(e.message ?? PaymentStrings.storePurchaseFailed,
          isError: true);
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    final revenueCat = context.read<RevenueCatService>();
    try {
      await revenueCat.restorePurchases();
    } on RevenueCatPurchaseException catch (e) {
      if (!mounted) return;
      setState(() => _restoring = false);
      context.showAppSnackBar(e.message ?? PaymentStrings.storePurchaseFailed,
          isError: true);
      return;
    }
    if (!mounted) return;
    setState(() => _restoring = false);
    if (revenueCat.isPlusActive) {
      await SubscriptionSuccessDialog.show(
          context, PaymentStrings.plusPlanName,
          restored: true);
      if (mounted) Navigator.of(context).pop();
    } else {
      context.showAppSnackBar(PaymentStrings.restoreNoActiveFound);
    }
  }

  String _labelFor(Package package) => switch (package.packageType) {
        PackageType.annual => PaymentStrings.planYearly,
        PackageType.monthly => PaymentStrings.planMonthly,
        _ => package.storeProduct.title,
      };

  @override
  Widget build(BuildContext context) {
    final expiresAt = context.watch<RevenueCatService>().plusExpiresAt;
    final packages = _packages;
    final hasSelection = packages != null && packages.isNotEmpty;
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
                  _buildPlanList(packages),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _restoring ? null : _restore,
                      child: Text(
                        PaymentStrings.restorePurchases,
                        style: TextStyle(
                          color: AppColors.grey2,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _buildLegalLinks(),
                ],
              ),
            ),
            _buildCheckoutButton(hasSelection, packages),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList(List<Package>? packages) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null || packages == null || packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? PaymentStrings.storePlansUnavailable,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey2, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadPackages,
              child: Text(PaymentStrings.retry,
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < packages.length; i++)
          StorePlanCard(
            package: packages[i],
            label: _labelFor(packages[i]),
            best: packages[i].packageType == PackageType.annual,
            selected: _selected == i,
            onTap: () => setState(() => _selected = i),
          ),
      ],
    );
  }

  Widget _buildLegalLinks() {
    final contact = _contact;
    final privacyLink = contact?.privacyLink;
    final termsLink = contact?.userAgreementLink;
    final hasPrivacy = privacyLink != null && privacyLink.isNotEmpty;
    final hasTerms = termsLink != null && termsLink.isNotEmpty;
    if (!hasPrivacy && !hasTerms) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (hasPrivacy)
            _LegalLinkButton(
              label: SettingsStrings.contactPrivacyPolicy,
              onTap: () => _openLink(privacyLink),
            ),
          if (hasPrivacy && hasTerms)
            Text('·',
                style: TextStyle(color: AppColors.grey3, fontSize: 12)),
          if (hasTerms)
            _LegalLinkButton(
              label: SettingsStrings.contactUserAgreement,
              onTap: () => _openLink(termsLink),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(bool hasSelection, List<Package>? packages) {
    final enabled = !_processing && hasSelection;
    final label = hasSelection
        ? PaymentStrings.storeSubscribeCta(
            packages![_selected].storeProduct.priceString)
        : PaymentStrings.subscriptionTitle;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.journeyMist,
        border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.55))),
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled || _processing ? 1 : 0.46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  enabled || _processing ? AppGradients.journeyPrimary : null,
              color: enabled || _processing ? null : AppColors.grey3,
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppGradients.journeyRoseVioletColors.last
                            .withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : const [],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: enabled ? _startCheckout : null,
                child: _processing
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLinkButton extends StatelessWidget {
  const _LegalLinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.grey2,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.grey3,
        ),
      ),
    );
  }
}
