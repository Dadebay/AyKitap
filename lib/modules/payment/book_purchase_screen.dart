import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book_detail.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/book_purchase_api_service.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/localization/strings/payment_strings.dart';
import 'balance_top_up.dart';
import 'widgets/book_purchase_confirm_button.dart';
import 'widgets/book_purchase_price_card.dart';
import 'widgets/book_purchase_summary_card.dart';
import 'widgets/insufficient_balance_dialog.dart';

/// Kitap satyn alyş sahypasy — TZ §10.2. A single-book checkout for a real
/// catalogue book: shows the cover, the price and the balance
/// ([AccountService.balanceManat], the same number Profile/[BalanceScreen]
/// show), then puts the purchase through [BookPurchaseApiService].
///
/// The balance is server-owned, so this never subtracts from it itself —
/// once the backend confirms the purchase, it re-reads `/users/me` and lets
/// the backend's number win.
///
/// Pops `true` once the purchase succeeds, which is
/// [CatalogBookDetailScreen]'s cue to refresh its CTA and go straight on to
/// downloading the book.
class BookPurchaseScreen extends StatefulWidget {
  final BookDetail book;
  const BookPurchaseScreen({super.key, required this.book});

  @override
  State<BookPurchaseScreen> createState() => _BookPurchaseScreenState();
}

class _BookPurchaseScreenState extends State<BookPurchaseScreen> {
  bool _processing = false;

  int get _price => widget.book.price ?? 0;

  Future<void> _confirm() async {
    if (_processing) return;
    final balance = context.read<AccountService>().balanceManat;
    if (balance == null || balance < _price) {
      await _offerTopUp(balance);
      return;
    }

    setState(() => _processing = true);
    try {
      await BookPurchaseApiService.buy(widget.book.id);
      // The backend has already moved the money; this just picks up the new
      // number rather than guessing at it.
      if (!mounted) return;
      await context.read<AccountService>().refresh();
      if (!mounted) return;
      await context.read<BookAccessService>().markPurchased(widget.book.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      context.showAppSnackBar(e.message, isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _processing = false);
    AnalyticsService.instance.logPurchase(
      bookId: '${widget.book.id}',
      value: _price.toDouble(),
      currency: 'TMT',
    );
    context.showAppSnackBar(PaymentStrings.purchasedSnackbar(widget.book.name));
    context.pop(true);
  }

  /// Balance short: the shared dialog explains the shortfall and, on
  /// "Töle", runs the normal money-in flow. Coming back with enough money
  /// retries the purchase straight away instead of making the user find the
  /// button again.
  Future<void> _offerTopUp(int? balance) async {
    final shortfall = balance == null ? null : _price - balance;
    final pay = await InsufficientBalanceDialog.show(context,
        shortfallManat: shortfall);
    if (!pay || !mounted) return;
    await startBalanceTopUp(context);
    if (!mounted) return;
    final refreshed = context.read<AccountService>().balanceManat;
    if (refreshed != null && refreshed >= _price) await _confirm();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final balance = context.watch<AccountService>().balanceManat;
    final enough = balance != null && balance >= _price;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        title: Text(PaymentStrings.purchaseTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  BookPurchaseSummaryCard(book: book),
                  const SizedBox(height: 20),
                  BookPurchasePriceCard(price: _price, balance: balance),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      HugeIcon(
                          icon: HugeIcons.strokeRoundedShield01,
                          color: AppColors.grey3,
                          size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(PaymentStrings.booksOnlyInApp,
                            style: TextStyle(
                                color: AppColors.grey3,
                                fontSize: 12.5,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            BookPurchaseConfirmButton(
              price: _price,
              enough: enough,
              processing: _processing,
              onConfirm: _confirm,
              onTopUp: () => _offerTopUp(balance),
            ),
          ],
        ),
      ),
    );
  }
}
