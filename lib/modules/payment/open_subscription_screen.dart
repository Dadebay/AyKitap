import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/purchase_mode_service.dart';
import 'store_subscription_screen.dart';
import 'subscription_screen.dart';

/// Guards every call below against a second tap landing while the first
/// one's [PurchaseModeService.refresh] round-trip is still in flight —
/// without it, a tap that produces no visible change for a second or two
/// reads as "didn't register" and gets repeated, stacking that many pushes
/// of the resolved screen once the awaits all resolve.
bool _isOpening = false;

/// Routes to whichever subscription screen can actually take the signed-in
/// user's money — [PurchaseModeService.useStoreCheckout] resolves a
/// Turkmenistan account to the TMT/[SubscriptionScreen] (bank card, promo
/// code, balance) and everyone else (plus every iOS account while the App
/// Store review toggle is on — see APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md) to
/// the store-billed [StoreSubscriptionScreen] (App Store/Play Store via
/// RevenueCat). Every "subscribe" entry point in the app should go through
/// this instead of pushing [SubscriptionScreen] directly — that screen has
/// no bank cards to offer a foreign user, so they'd land on a plan list with
/// no way to complete a purchase.
///
/// [PurchaseModeService.refresh] never throws — a config error fails closed
/// to the store screen on iOS (never quietly reopening a payment path Apple
/// rejected) and to [SubscriptionScreen] on Android, matching its
/// pre-existing default.
Future<void> openSubscriptionScreen(BuildContext context) async {
  if (_isOpening) return;
  _isOpening = true;
  // Captured before the first await: this still works if the widget that was
  // tapped is gone by the time [refresh] answers, which is what used to
  // strand the spinner below (the old code returned early on
  // `!context.mounted`, leaving a non-dismissible barrier over the app with
  // no route ever pushed — "Abuna" looked dead while Settings, which pushes
  // its screen directly and skips all of this, kept working).
  final navigator = Navigator.of(context, rootNavigator: true);
  // Immediate feedback for the [refresh] round-trip below — a cold
  // RevenueCat SDK (fetching remote config, offerings and store product
  // details, as seen in the debug logs) can take a couple of seconds, and
  // this screen would otherwise sit there looking untouched the whole time.
  BuildContext? spinnerContext;
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black26,
    builder: (dialogContext) {
      spinnerContext = dialogContext;
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    },
  ));
  final purchaseMode = PurchaseModeService.instance;
  try {
    // Bounded on purpose. [DioClient] allows 15s to connect and 15s to
    // receive, and retries once against the fallback host — so on a bad
    // connection this await could hold the spinner for the better part of a
    // minute, which is indistinguishable from the button not working. The
    // config is only a routing hint: [refresh] never throws and keeps its
    // last-known answer (store-only on iOS), so giving up early costs a
    // possibly-stale route, not correctness.
    await purchaseMode.refresh().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
  } finally {
    // Always, on every path — a latch that sticks disables every "subscribe"
    // entry point in the app until it is restarted.
    _isOpening = false;
    final spinner = spinnerContext;
    if (spinner != null && spinner.mounted) Navigator.of(spinner).pop();
  }
  await navigator.push(MaterialPageRoute(
    builder: (_) => purchaseMode.useStoreCheckout
        ? const StoreSubscriptionScreen()
        : const SubscriptionScreen(),
  ));
}
