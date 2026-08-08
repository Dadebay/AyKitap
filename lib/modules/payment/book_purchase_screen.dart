import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book_detail.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/book_purchase_api_service.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/network_cover_image.dart';
import '../../core/localization/strings/payment_strings.dart';
import 'balance_top_up.dart';
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
    final balance = AccountService.instance.balanceManat;
    if (balance == null || balance < _price) {
      await _offerTopUp(balance);
      return;
    }

    setState(() => _processing = true);
    try {
      await BookPurchaseApiService.buy(widget.book.id);
      // The backend has already moved the money; this just picks up the new
      // number rather than guessing at it.
      await AccountService.instance.refresh();
      await BookAccessService.instance.markPurchased(widget.book.id);
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
    final pay = await InsufficientBalanceDialog.show(context, shortfallManat: shortfall);
    if (!pay || !mounted) return;
    await startBalanceTopUp(context);
    if (!mounted) return;
    final refreshed = AccountService.instance.balanceManat;
    if (refreshed != null && refreshed >= _price) await _confirm();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final balance = context.watch<AccountService>().balanceManat;
    final enough = balance != null && balance >= _price;
    final image = book.image;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        title: Text(PaymentStrings.purchaseTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  // Book summary card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 92,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: image != null && image.isNotEmpty
                                ? NetworkCoverImage(url: ApiConfig.resolveImageUrl(image), placeholder: (_) => _CoverPlaceholder())
                                : _CoverPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.name, style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (book.authors.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(book.authorNames, style: TextStyle(color: AppColors.grey2, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                              if (book.bookFiles.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  book.bookFiles.map((f) => f.fileFormat.toUpperCase()).toSet().join(' · '),
                                  style: TextStyle(color: AppColors.grey3, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Price + balance breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _row(PaymentStrings.bookPrice, PaymentStrings.manat(_price)),
                        const SizedBox(height: 12),
                        _row(PaymentStrings.yourBalance, balance != null ? PaymentStrings.manat(balance) : '…', valueColor: enough ? AppColors.grey1 : Colors.redAccent),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.border, height: 1),
                        ),
                        _row(
                          PaymentStrings.afterPurchase,
                          enough ? PaymentStrings.manat(balance - _price) : PaymentStrings.notEnough,
                          bold: true,
                          valueColor: enough ? AppColors.white : Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                  if (!enough) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(PaymentStrings.balanceInsufficientNote, style: TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedShield01, color: AppColors.grey3, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(PaymentStrings.booksOnlyInApp, style: TextStyle(color: AppColors.grey3, fontSize: 12.5, height: 1.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Sticky action
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _processing
                      ? null
                      : enough
                          ? _confirm
                          : () => _offerTopUp(balance),
                  child: _processing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                      : Text(
                          enough ? PaymentStrings.confirmWithPrice(_price) : PaymentStrings.topUpBalance,
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

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.grey2, fontSize: bold ? 14.5 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.grey1, fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey3, size: 20)),
    );
  }
}
