import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/book.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/book_detail_strings.dart';

/// §10.1.5–6: read count · purchase count · pages, plus the format pill.
class DetailStatsRow extends StatelessWidget {
  const DetailStatsRow({super.key, required this.book});

  final Book book;

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MetaStat(value: _fmt(book.readCount), label: BookDetailStrings.statRead),
            const _MetaDivider(),
            _MetaStat(value: _fmt(book.purchaseCount), label: BookDetailStrings.statPurchased),
            const _MetaDivider(),
            _MetaStat(value: '${book.pages}', label: BookDetailStrings.statPages),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedFile01, color: AppColors.grey2, size: 14),
              const SizedBox(width: 6),
              Text(book.format.label, style: TextStyle(color: AppColors.grey1, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaStat extends StatelessWidget {
  final String value;
  final String label;
  const _MetaStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.border,
    );
  }
}
