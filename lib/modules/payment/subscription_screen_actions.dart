part of 'subscription_screen.dart';

/// [_SubscriptionScreenState]'s payment-flow methods — split out of
/// subscription_screen.dart to keep that file under the 200-line limit.
/// Pure mechanical move: every expression here is unchanged from before the
/// split, aside from `AccountService`/`SubscriptionService.instance` calls
/// switched to `context.read<...>()` (both are registered
/// `ChangeNotifierProvider`s in main.dart — see refactor-progress.md).
extension _SubscriptionScreenActions on _SubscriptionScreenState {
  Future<void> _loadTariffs() async {
    _setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tariffs = await PaymentApiService.getTariffs();
      if (!mounted) return;
      _setState(() {
        _tariffs = tariffs;
        _loading = false;
        // Default to the best-value plan (biggest discount) rather than
        // always the 2nd one — with a dynamic tariff list there's no fixed
        // "monthly is always index 1" to lean on anymore.
        _selected = bestSubscriptionPlanIndex(tariffs);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _startCheckout() async {
    final tariffs = _tariffs;
    if (_processing || tariffs == null || tariffs.isEmpty) return;
    final tariff = tariffs[_selected];

    unawaited(AnalyticsService.instance.logPurchaseStep(
      step: 'started',
      productType: 'subscription',
      productId: '${tariff.id}',
      source: 'backend_balance',
      value: tariff.price,
    ));
    _setState(() => _processing = true);
    bool ok;
    try {
      ok = await context
          .read<SubscriptionService>()
          .subscribe(tariffId: tariff.id, priceManat: tariff.price);
    } on ApiException catch (e) {
      unawaited(AnalyticsService.instance.logPurchaseStep(
        step: 'failed',
        productType: 'subscription',
        productId: '${tariff.id}',
        source: 'backend_balance',
        value: tariff.price,
      ));
      if (!mounted) return;
      _setState(() => _processing = false);
      context.showAppSnackBar(e.message, isError: true);
      return;
    }
    if (!mounted) return;
    _setState(() => _processing = false);

    if (ok) {
      unawaited(AnalyticsService.instance.logPurchaseStep(
        step: 'completed',
        productType: 'subscription',
        productId: '${tariff.id}',
        source: 'backend_balance',
        value: tariff.price,
      ));
      await SubscriptionSuccessDialog.show(
          context, subscriptionPlanLabel(tariff));
    } else {
      unawaited(AnalyticsService.instance.logPurchaseStep(
        step: 'blocked',
        productType: 'subscription',
        productId: '${tariff.id}',
        source: 'insufficient_balance',
        value: tariff.price,
      ));
      await _showInsufficientBalanceDialog();
    }
  }

  /// Shown when [SubscriptionService.subscribe] can't debit the plan's
  /// price from the balance — the same dialog a single-book purchase uses
  /// ([InsufficientBalanceDialog]), differing only in the follow-up: a plan
  /// hands off to [PaymentMethodSheet] directly so the user can pick promo
  /// code vs. bank card, rather than the book flow's [startBalanceTopUp].
  Future<void> _showInsufficientBalanceDialog() async {
    final pay = await InsufficientBalanceDialog.show(
      context,
      note: PaymentStrings.subscriptionBalanceInsufficientNote,
    );
    if (pay && mounted) await _choosePaymentMethod();
  }

  Future<void> _choosePaymentMethod() async {
    // showStore stays false here — a subscription is always priced in TMT
    // from the balance, so this checkout only ever offers promo code/bank;
    // the store branch is balance-top-up-only (see startBalanceTopUp).
    final choice = await PaymentMethodSheet.show(context);
    if (choice == null || !mounted) return;
    switch (choice) {
      case PaymentMethodChoice.promoCode:
        await _payWithPromoCode();
      case PaymentMethodChoice.bankCard:
        await _payWithBank();
      case PaymentMethodChoice.store:
        break;
    }
  }

  /// Redeems the code via `POST /users/promo-codes` — the backend credits
  /// the balance, not the plan directly, so this just refreshes
  /// [AccountService] and then re-runs the normal balance-funded checkout
  /// (which now might actually cover the price).
  Future<void> _payWithPromoCode() async {
    final code = await PromoCodeSheet.show(context);
    if (code == null || code.isEmpty || !mounted) return;

    _setState(() => _processing = true);
    try {
      await AuthApiService.redeemPromoCode(code: code);
      if (!mounted) return;
      await context.read<AccountService>().refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(() => _processing = false);
      context.showAppSnackBar(e.message, isError: true);
      return;
    }
    if (!mounted) return;
    _setState(() => _processing = false);
    context.showAppSnackBar(PaymentStrings.promoCodeAppliedBalance);
    await _startCheckout();
  }

  /// Tops up the balance by exactly the selected plan's price and, once the
  /// webview closes, re-reads the balance and retries [_startCheckout] —
  /// same "top up, then retry" shape as [BookPurchaseScreen]'s insufficient-
  /// balance path. There's no "pay for this subscription via bank" endpoint
  /// of its own; [PaymentEndpoints.paymentOrders] is the only bank-card money-in
  /// route, so a subscription bought this way is still two steps under the
  /// hood (top up, then [SubscriptionService.subscribe] spends from it).
  Future<void> _payWithBank() async {
    final tariffs = _tariffs;
    if (_processing || tariffs == null || tariffs.isEmpty) return;
    final bank = await BankSelectSheet.show(context);
    if (bank == null || !mounted) return;

    _setState(() => _processing = true);
    final tariff = tariffs[_selected];
    try {
      final url = await PaymentApiService.createTopUpOrder(
          amount: tariff.price, bankId: bank.id);
      if (!mounted) return;
      _setState(() => _processing = false);
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: url)));
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(() => _processing = false);
      context.showAppSnackBar(e.message, isError: true);
      return;
    }
    if (!mounted) return;
    await context.read<AccountService>().refresh();
    if (!mounted) return;
    final balance = context.read<AccountService>().balanceManat;
    if (balance != null && balance >= tariff.price) await _startCheckout();
  }
}
