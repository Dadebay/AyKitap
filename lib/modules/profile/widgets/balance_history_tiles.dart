import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/models/balance_log.dart';
import '../../../core/models/payment_order.dart';
import '../../../core/theme/app_colors.dart';

class BalanceLogTile extends StatelessWidget {
  const BalanceLogTile({required this.log, super.key});

  final BalanceLog log;

  @override
  Widget build(BuildContext context) {
    final isPurchase = log.isBookPurchase;
    final color =
        isPurchase ? const Color(0xFFE65C5C) : const Color(0xFF3FBE6C);
    final title = isPurchase
        ? (log.bookName?.isNotEmpty == true
            ? log.bookName!
            : ProfileStrings.balanceBookPurchase)
        : log.event.toUpperCase().contains('DEPOSIT') ||
                log.event.toUpperCase().contains('PROMO')
            ? ProfileStrings.balanceTopUp
            : ProfileStrings.balanceOtherActivity;
    final subtitle = isPurchase
        ? ProfileStrings.balanceBookPurchase
        : log.event.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            colors: [AppColors.card, color.withValues(alpha: .075)]),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _icon(color, isPurchase),
            const SizedBox(width: 12),
            Expanded(child: _title(title, subtitle, color)),
            const SizedBox(width: 10),
            _amount(log, color),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Divider(
                height: 1, color: AppColors.border.withValues(alpha: .75)),
          ),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 15, color: AppColors.grey2),
            const SizedBox(width: 6),
            Text(DateFormat.yMMMd().add_Hm().format(log.createdAt),
                style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(
                log.isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 15,
                color: color),
          ]),
        ],
      ),
    );
  }

  Widget _icon(Color color, bool isPurchase) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(16)),
        child: Icon(
            isPurchase ? Icons.menu_book_rounded : Icons.savings_rounded,
            color: color,
            size: 23),
      );

  Widget _title(String title, String subtitle, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _amount(BalanceLog log, Color color) => Text(
        '${log.isCredit ? '+' : '-'}${PaymentStrings.manat(log.amount.abs())}',
        style:
            TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
      );
}

class PaymentOrderTile extends StatelessWidget {
  const PaymentOrderTile({required this.order, super.key});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context) {
    final logo = order.bank.logoAsset;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12)),
          child: logo == null
              ? Center(
                  child: HugeIcon(
                      icon: HugeIcons.strokeRoundedBank,
                      color: AppColors.grey2,
                      size: 20))
              : Image.asset(logo, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.bank.name,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(DateFormat.yMMMd().add_Hm().format(order.createdAt),
              style: TextStyle(
                  color: AppColors.grey2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ])),
        Text(PaymentStrings.manat(order.amount),
            style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
