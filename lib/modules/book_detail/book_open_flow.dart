import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/strings/book_detail_strings.dart';
import '../../core/models/book_detail.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_hero_tags.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/book_download_service.dart';
import '../../core/services/downloaded_books_store.dart';
import '../../core/services/downloaded_files_store.dart';
import '../../core/services/last_read_book_store.dart';
import '../../core/services/reading_books_store.dart';
import '../../core/widgets/app_snackbar.dart';
import '../auth/phone_login_screen.dart';
import '../payment/balance_top_up.dart';
import '../payment/book_purchase_screen.dart';
import '../payment/subscription_screen.dart';
import '../payment/widgets/insufficient_balance_dialog.dart';
import '../payment/widgets/subscription_required_dialog.dart';
import '../reader/utils/catalog_book_opener.dart';

part 'book_open_flow_actions.dart';

/// Everything that happens between tapping "Oku" and a reader appearing:
/// the access gate, the login/top-up/purchase detours it can send the user
/// on, the download, and the hand-off to whichever reader the file's format
/// calls for.
///
/// Lives outside [CatalogBookDetailScreen] so that screen stays a screen —
/// and so the same flow can be reused from anywhere else that opens a
/// catalogue book (a downloaded shelf tap, a notification).
class BookOpenFlow {
  final BuildContext context;
  final BookDetail book;

  /// Fired after anything that could change the access verdict (a login, a
  /// completed purchase) so the CTA row can re-resolve.
  final VoidCallback? onAccessChanged;

  const BookOpenFlow({
    required this.context,
    required this.book,
    this.onAccessChanged,
  });

  /// The "Oku" path: resolve access, clear whatever is in the way, then
  /// download (if needed) and open.
  ///
  /// [_retries] guards the one place this re-enters itself — after a login
  /// or purchase the verdict is re-resolved, and a backend that keeps
  /// answering "needsPurchase" must not turn that into an endless loop of
  /// checkout screens.
  Future<void> read(
      {int retries = 2, bool offerPurchasedExport = false}) async {
    final bookAccess = context.read<BookAccessService>();
    final access = await bookAccess.resolve(book);
    if (!context.mounted) return;

    switch (access) {
      case BookAccess.purchased:
        await _downloadAndOpen(offerPurchasedExport: offerPurchasedExport);
      case BookAccess.subscription:
        await _downloadAndOpen();

      case BookAccess.needsLogin:
        if (retries <= 0) return;
        final loggedIn = await _login();
        if (loggedIn && context.mounted) await read(retries: retries - 1);

      // "Oka" doesn't assume the reader wants to buy just this one book —
      // that's what a separate "Satyn al" tap means (see [buy] below, which
      // still goes straight to purchase/top-up). Not owned and not
      // subscribed means offering both ways forward.
      case BookAccess.needsPurchase:
      case BookAccess.needsTopUp:
        if (retries <= 0) return;
        final choice = await SubscriptionRequiredDialog.show(context);
        if (choice == null || !context.mounted) return;
        switch (choice) {
          case SubscriptionPromptChoice.subscribe:
            await context.push(const SubscriptionScreen());
            // Whether or not they actually subscribed, the CTA row's
            // verdict may have changed — same "refresh, let the reader tap
            // again" restraint [_topUp] uses below, rather than assuming
            // success and reopening the reader on their behalf.
            if (context.mounted) onAccessChanged?.call();
          case SubscriptionPromptChoice.buy:
            final bought = await buy();
            if (bought && context.mounted) await read(retries: retries - 1);
        }
    }
  }

  /// The "Satyn al" path. Returns true when the book ends up owned — which
  /// is also the case when it already was (a second tap while the CTA was
  /// stale), so the caller can just go on to opening it.
  Future<bool> buy({int retries = 2}) async {
    final bookAccess = context.read<BookAccessService>();
    final access = await bookAccess.resolve(book);
    if (!context.mounted) return false;

    switch (access) {
      case BookAccess.purchased:
        return true;

      case BookAccess.needsLogin:
        if (retries <= 0) return false;
        final loggedIn = await _login();
        if (!loggedIn || !context.mounted) return false;
        return buy(retries: retries - 1);

      case BookAccess.needsTopUp:
        await _topUp();
        if (!context.mounted) return false;
        onAccessChanged?.call();
        // The top-up may well have covered the price — re-resolve once
        // rather than making the user tap "Satyn al" again.
        if (retries <= 0) return false;
        final resolved = await bookAccess.resolve(book);
        if (resolved != BookAccess.needsPurchase || !context.mounted)
          return false;
        return buy(retries: retries - 1);

      // An active subscriber can still buy a book outright — that's the
      // point of buying one: it outlives the subscription.
      case BookAccess.subscription:
      case BookAccess.needsPurchase:
        final bought = await context.push<bool>(BookPurchaseScreen(book: book));
        if (!context.mounted) return false;
        onAccessChanged?.call();
        return bought == true;
    }
  }
}
