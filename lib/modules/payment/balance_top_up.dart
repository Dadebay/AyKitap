import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/payment_api_service.dart';
import '../../core/services/revenue_cat_api_service.dart';
import '../../core/services/revenue_cat_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/payment_strings.dart';
import 'payment_webview_screen.dart';
import 'widgets/bank_select_sheet.dart';
import 'widgets/payment_method_sheet.dart';
import 'widgets/promo_code_sheet.dart';
import 'widgets/store_topup_sheet.dart';
import 'widgets/top_up_amount_sheet.dart';

/// "Balans doldur" — the shared money-in flow, started from the profile's
/// [BalanceCard] (and reusable anywhere a purchase finds the balance short).
///
/// Deliberately the *same* first step as a subscription checkout
/// ([PaymentMethodSheet]: promo code or bank card) so there's one mental
/// model for paying in this app; only the follow-up differs — a top-up has
/// no tariff to price it, so the bank branch asks for an amount first. A
/// third, store-billed branch (App Store/Google Play via RevenueCat) is
/// offered too, but only once `RevenueCatApiService.getConfig` confirms the
/// signed-in user is on the foreign/store billing path — the local bank
/// branch only accepts Turkmenistan bank cards, so that's the one users
/// outside Turkmenistan actually need.
///
/// The balance itself is server-owned ([AccountService]), so this never
/// edits it locally: it re-reads `/users/me` afterwards and lets the
/// backend's number win — the bank branch does that *after* the webview
/// closes, whether the user actually finished paying or backed out, since
/// there's no other way to know from here which one happened; the store
/// branch does the same after a purchase, since the actual credit only
/// lands once the reconcile call (or, failing that, the webhook) applies it
/// server-side.
Future<void> startBalanceTopUp(BuildContext context) async {
  final showStore = await _canOfferStoreTopUp();
  if (!context.mounted) return;
  final choice = await PaymentMethodSheet.show(context, showStore: showStore);
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case PaymentMethodChoice.promoCode:
      final code = await PromoCodeSheet.show(context);
      if (code == null || code.isEmpty || !context.mounted) return;
      try {
        await AuthApiService.redeemPromoCode(code: code);
        if (context.mounted)
          context.showAppSnackBar(PaymentStrings.promoCodeAppliedBalance);
      } on ApiException catch (e) {
        if (!context.mounted) return;
        context.showAppSnackBar(e.message, isError: true);
      }

    case PaymentMethodChoice.bankCard:
      final amount = await TopUpAmountSheet.show(context);
      if (amount == null || !context.mounted) return;
      final bank = await BankSelectSheet.show(context);
      if (bank == null || !context.mounted) return;
      try {
        final url = await PaymentApiService.createTopUpOrder(
            amount: amount, bankId: bank.id);
        if (!context.mounted) return;
        await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: url)));
      } on ApiException catch (e) {
        if (!context.mounted) return;
        context.showAppSnackBar(e.message, isError: true);
      }

    case PaymentMethodChoice.store:
      final package = await StoreTopUpSheet.show(context);
      if (package == null || !context.mounted) return;
      try {
        final info = await RevenueCatService.instance.purchasePackage(package);
        if (info == null) return; // user cancelled — not an error
        try {
          await RevenueCatApiService.reconcile();
        } catch (_) {
          // Best-effort — the webhook will still credit the balance on its
          // own if this reconcile call fails.
        }
        if (context.mounted) {
          context.showAppSnackBar(PaymentStrings.storeTopUpApplied);
        }
      } on RevenueCatPurchaseException catch (e) {
        if (!context.mounted) return;
        context.showAppSnackBar(e.message ?? PaymentStrings.storeTopUpFailed,
            isError: true);
      }
  }

  // Whatever the branch did, the server is the authority on the balance.
  if (context.mounted) await AccountService.instance.refresh();
}

/// Whether [PaymentMethodSheet] should offer the store branch at all —
/// checked fresh on every top-up rather than cached, since a user's region
/// can only really change between sessions but the config call is cheap and
/// this keeps the gate as the single source of truth. Fails closed: no
/// network, RevenueCat not configured, or any other error just means the
/// store option stays hidden and the existing promo/bank flow is unaffected.
Future<bool> _canOfferStoreTopUp() async {
  if (!Platform.isIOS && !Platform.isAndroid) return false;
  if (!RevenueCatService.instance.isReady) return false;
  try {
    final config = await RevenueCatApiService.getConfig();
    return config.isStoreIap;
  } catch (_) {
    return false;
  }
}
