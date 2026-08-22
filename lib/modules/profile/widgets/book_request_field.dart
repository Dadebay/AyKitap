import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// [BookRequestSheet]'s field label — split out to keep that file under the
/// 200-line limit.
class BookRequestFieldLabel extends StatelessWidget {
  final String label;
  const BookRequestFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            color: AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w600));
  }
}

/// [BookRequestSheet]'s card-background text field — split out to keep that
/// file under the 200-line limit.
class BookRequestTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const BookRequestTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: maxLines == 1 ? 50 : null,
      margin: const EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: maxLines == 1 ? 0 : 12),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(color: AppColors.white, fontSize: 14),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.grey3),
            border: InputBorder.none),
      ),
    );
  }
}
