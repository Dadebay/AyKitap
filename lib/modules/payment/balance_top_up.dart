import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/localization/strings/payment_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/balance_alert_service.dart';
import '../../core/services/payment_api_service.dart';
import '../../core/services/purchase_mode_service.dart';
import '../../core/services/revenue_cat_api_service.dart';
import '../../core/services/revenue_cat_service.dart';
import '../../core/widgets/app_snackbar.dart';
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
Future<void> startBalanceTopUp(
  BuildContext context, {
  Future<bool>? storeTopUpAvailability,
}) async {
  // Two of the three routes below hand off to another app on the way (Play's
  // billing activity, the bank's payment page), so coming back is a
  // `resumed` that [BalanceAlertService] would otherwise read as money
  // arriving from nowhere — and announce over the success UI the reader is
  // already looking at. Armed here rather than at each success branch so a
  // route that credits without one still can't trip it.
  BalanceAlertService.instance.ignoreNextIncrease();
  final useStore = await _mustUseStoreTopUp(storeTopUpAvailability);
  if (!context.mounted) return;
  if (useStore) {
    // The store path used to go straight to the store sheet, which is why a
    // reader on it saw no promo code anywhere in the app — it lives in
    // [PaymentMethodSheet], and that sheet was skipped. A promo code needs
    // no bank card, so there is no reason the store path can't offer it; the
    // bank-card row is the only one that genuinely doesn't apply, and it is
    // dropped instead.
    //
    // Gated on the admin panel's "Diňe App Store tölegleri" switch, which is
    // what [PurchaseModeService.isIOSStoreOnly] carries: while it is on, iOS
    // sells through App Store alone and nothing else may be offered (see the
    // panel's own 3.1.1 warning). Off — and on Android, where the switch has
    // no effect at all — the promo code is shown.
    if (PurchaseModeService.instance.isIOSStoreOnly) {
      await _purchaseStoreTopUp(context);
      if (context.mounted) await AccountService.instance.refresh();
      return;
    }
    final storeChoice = await PaymentMethodSheet.show(context,
        showStore: true, showBankCard: false);
    if (storeChoice == null || !context.mounted) return;
    if (storeChoice == PaymentMethodChoice.promoCode) {
      await _redeemPromoCode(context);
    } else {
      await _purchaseStoreTopUp(context);
    }
    if (context.mounted) await AccountService.instance.refresh();
    return;
  }

  final choice = await PaymentMethodSheet.show(context);
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case PaymentMethodChoice.promoCode:
      await _redeemPromoCode(context);

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
      await _purchaseStoreTopUp(context);
  }

  // Whatever the branch did, the server is the authority on the balance.
  if (context.mounted) await AccountService.instance.refresh();
}

/// Whether a native user must use the store path. Foreign accounts must not
/// fall back to Turkmen bank cards when the store offering cannot load, and
/// (per APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md) an iOS account must never
/// fall back to promo code/bank card while the App Store review toggle is
/// on — [PurchaseModeService.useStoreCheckout] already encodes both rules,
/// including failing closed to the store surface on iOS.
/// Asks for a code and redeems it, crediting the balance server-side.
/// Shared by both branches above so the store path redeems exactly the way
/// the wallet path always has.
Future<void> _redeemPromoCode(BuildContext context) async {
  final code = await PromoCodeSheet.show(context);
  if (code == null || code.isEmpty || !context.mounted) return;
  try {
    await AuthApiService.redeemPromoCode(code: code);
    if (context.mounted) {
      context.showAppSnackBar(PaymentStrings.promoCodeAppliedBalance);
    }
  } on ApiException catch (e) {
    if (!context.mounted) return;
    context.showAppSnackBar(e.message, isError: true);
  }
}

Future<bool> _mustUseStoreTopUp(Future<bool>? storeTopUpAvailability) async {
  if (!Platform.isIOS && !Platform.isAndroid) return false;
  if (storeTopUpAvailability != null) return storeTopUpAvailability;
  await PurchaseModeService.instance.refresh();
  return PurchaseModeService.instance.useStoreCheckout;
}

Future<void> _purchaseStoreTopUp(BuildContext context) async {
  final package = await StoreTopUpSheet.show(context);
  if (package == null || !context.mounted) return;
  try {
    final info = await RevenueCatService.instance.purchasePackage(package);
    if (info == null) return; // user cancelled — not an error
    try {
      await RevenueCatApiService.reconcile();
    } catch (_) {
      // Best-effort — the webhook will still credit the balance on its own.
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
