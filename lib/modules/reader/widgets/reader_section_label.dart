import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A settings-sheet section heading: small, muted, uppercase-weight text.
/// Shared by the EPUB, PDF and CBZ settings sheets, which used to each carry
/// an identical private copy.
class ReaderSectionLabel extends StatelessWidget {
  final String text;
  const ReaderSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            color: AppColors.grey2,
            fontSize: 12.5,
            fontWeight: FontWeight.w600));
  }
}
