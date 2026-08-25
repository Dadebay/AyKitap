import 'package:flutter/material.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/theme/app_colors.dart';

/// What the user picked on [SubscriptionRequiredDialog].
enum SubscriptionPromptChoice { subscribe, buy }

/// Shown from the book detail page's "Oka" button when the book isn't owned
/// or covered by an active subscription — offers the two ways forward
/// ([BookOpenFlow.read] resolves back to one of these) rather than assuming
/// the reader wants to buy just this one book, which is what "Satyn al"
/// (and its own [InsufficientBalanceDialog] path) is for.
class SubscriptionRequiredDialog extends StatelessWidget {
  const SubscriptionRequiredDialog({super.key});

  static Future<SubscriptionPromptChoice?> show(BuildContext context) {
    return showDialog<SubscriptionPromptChoice>(
      context: context,
      builder: (_) => const SubscriptionRequiredDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Center(
              child: ClipOval(
                child: Image.asset('assets/images/logo.webp',
                    width: 46, height: 46, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            PaymentStrings.subscriptionRequiredTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            PaymentStrings.subscriptionRequiredBody,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () =>
                Navigator.pop(context, SubscriptionPromptChoice.subscribe),
            child: Text(PaymentStrings.subscribeCta,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () =>
                Navigator.pop(context, SubscriptionPromptChoice.buy),
            child: Text(BookDetailStrings.buy,
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(PaymentStrings.close,
                style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
