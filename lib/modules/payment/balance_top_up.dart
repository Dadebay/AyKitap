import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/payment_strings.dart';
import 'widgets/bank_select_sheet.dart';
import 'widgets/payment_method_sheet.dart';
import 'widgets/promo_code_sheet.dart';
import 'widgets/top_up_amount_sheet.dart';

/// "Balans doldur" — the shared money-in flow, started from the profile's
/// [BalanceCard] (and reusable anywhere a purchase finds the balance short).
///
/// Deliberately the *same* first step as a subscription checkout
/// ([PaymentMethodSheet]: promo code or bank card) so there's one mental
/// model for paying in this app; only the follow-up differs — a top-up has
/// no tariff to price it, so the bank branch asks for an amount first.
///
/// The balance itself is server-owned ([AccountService]), so this never
/// edits it locally: it re-reads `/users/me` afterwards and lets the
/// backend's number win.
///
/// MISSING BACKEND: there is still no top-up-balance (bank card) endpoint —
/// `/payments/*` only exposes tariffs, banks, and the unconfirmed
/// subscribe-initiate — so that branch still stops at
/// [PaymentStrings.topUpNotAvailable]. The promo-code branch is real
/// ([AuthApiService.redeemPromoCode]).
Future<void> startBalanceTopUp(BuildContext context) async {
  final choice = await PaymentMethodSheet.show(context);
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case PaymentMethodChoice.promoCode:
      final code = await PromoCodeSheet.show(context);
      if (code == null || code.isEmpty || !context.mounted) return;
      try {
        await AuthApiService.redeemPromoCode(code: code);
        if (context.mounted) context.showAppSnackBar(PaymentStrings.promoCodeAppliedBalance);
      } on ApiException catch (e) {
        if (!context.mounted) return;
        context.showAppSnackBar(e.message, isError: true);
      }

    case PaymentMethodChoice.bankCard:
      final amount = await TopUpAmountSheet.show(context);
      if (amount == null || !context.mounted) return;
      final bank = await BankSelectSheet.show(context);
      if (bank == null || !context.mounted) return;
      // TODO(backend): POST top-up initiate {amount, bank_id} -> payment URL,
      // then push PaymentWebViewScreen with it (same shape as
      // SubscriptionScreen._payWithBank).
      context.showAppSnackBar(PaymentStrings.topUpNotAvailable, isError: true);
  }

  // Whatever the branch did, the server is the authority on the balance.
  await AccountService.instance.refresh();
}
