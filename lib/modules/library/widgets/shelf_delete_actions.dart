import 'package:flutter/material.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'shelf_delete.dart' show ShelfDeleteChoice;

/// The delete / optional-extra / cancel button stack at the bottom of the
/// shelf-delete confirmation dialog.
class ShelfDeleteActions extends StatelessWidget {
  final String? extraLabel;
  static const _danger = Color(0xFFE5484D);

  const ShelfDeleteActions({super.key, this.extraLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, ShelfDeleteChoice.delete),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(LibraryStrings.delete,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        if (extraLabel != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            // Outlined, not filled: it's a real alternative to deleting
            // (keep a copy of the file first), but the card should still
            // read as one decision, not two competing buttons.
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, ShelfDeleteChoice.extra),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(extraLabel!,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 44,
          // The safe way out is the plainest thing on the card: the
          // destructive button is the only filled one, so a half-read
          // dialog can't be dismissed *into* the delete.
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BookDetailStrings.cancel,
                style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
