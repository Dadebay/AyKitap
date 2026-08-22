import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

/// One "17K / Okaldy" style stat in [CatalogBookDetailScreen]'s stats row.
class CatalogDetailMetaStat extends StatelessWidget {
  final String value;
  final String label;
  const CatalogDetailMetaStat(
      {super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
      ],
    );
  }
}

/// The vertical hairline between two [CatalogDetailMetaStat]s.
class CatalogDetailMetaDivider extends StatelessWidget {
  const CatalogDetailMetaDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.border);
  }
}

/// A small pill (file format / age rating / year) in the info row under the
/// title.
class CatalogDetailInfoPill extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  const CatalogDetailInfoPill(
      {super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: AppColors.grey2, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: AppColors.grey1,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
