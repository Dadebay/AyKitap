import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../../core/services/streak_service.dart';
import '../profile/finance_screen.dart';
import '../../core/localization/strings/payment_strings.dart';

/// Kitap satyn alyş sahypasy — TZ §10.2. A single-book checkout: shows the
/// cover, price and the on-device balance, then debits the balance via
/// [StreakService.spendBalance]. Pops `true` once the purchase succeeds so
/// [BookDetailScreen] can flip its CTA from "Satyn al" to "Oka".
class BookPurchaseScreen extends StatefulWidget {
  final Book book;
  const BookPurchaseScreen({super.key, required this.book});

  @override
  State<BookPurchaseScreen> createState() => _BookPurchaseScreenState();
}

class _BookPurchaseScreenState extends State<BookPurchaseScreen> {
  bool _processing = false;

  Future<void> _confirm() async {
    if (_processing) return;
    setState(() => _processing = true);
    final ok = await StreakService.instance.spendBalance(widget.book.priceManat);
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PaymentStrings.purchasedSnackbar(widget.book.title)), backgroundColor: AppColors.primary),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PaymentStrings.balanceNotEnough)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(PaymentStrings.purchaseTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: StreakService.instance,
        builder: (context, _) {
          final balance = StreakService.instance.balanceManat;
          final enough = balance >= book.priceManat;
          return SafeArea(
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
                                child: Image.asset(book.coverImage, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(book.title, style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(book.author.name, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text(book.format.label, style: TextStyle(color: AppColors.grey3, fontSize: 12, fontWeight: FontWeight.w600)),
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
                            _row(PaymentStrings.bookPrice, PaymentStrings.manat(book.priceManat)),
                            const SizedBox(height: 12),
                            _row(PaymentStrings.yourBalance, PaymentStrings.manat(balance), valueColor: enough ? AppColors.grey1 : Colors.redAccent),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: AppColors.border, height: 1),
                            ),
                            _row(
                              PaymentStrings.afterPurchase,
                              enough ? PaymentStrings.manat(balance - book.priceManat) : PaymentStrings.notEnough,
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
                            HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: Colors.redAccent, size: 16),
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
                              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
                      child: _processing
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                          : Text(
                              enough ? PaymentStrings.confirmWithPrice(book.priceManat) : PaymentStrings.topUpBalance,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
