import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Grab handle + title + circular close button, shared by the EPUB, PDF and
/// CBZ settings sheets — each used to carry an identical copy (only the
/// close icon differed). Always dismisses via `Navigator.pop(context)`.
class ReaderSheetHeader extends StatelessWidget {
  final String title;
  final Widget closeIcon;

  const ReaderSheetHeader(
      {super.key, required this.title, required this.closeIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.grey3, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(title,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: AppColors.card, shape: BoxShape.circle),
                child: closeIcon,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
