import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/reader_pdf_strings.dart';

/// Jump straight to a page number. The bottom bar's scrubber covers rough
/// movement, but on a 300-page scan one pixel of track is several pages — this
/// is how you land on an exact one.
///
/// Pops with the chosen 1-based page, or null if dismissed.
class PdfGoToPageSheet extends StatefulWidget {
  final int currentPage; // 1-based
  final int totalPages;

  const PdfGoToPageSheet(
      {super.key, required this.currentPage, required this.totalPages});

  @override
  State<PdfGoToPageSheet> createState() => _PdfGoToPageSheetState();
}

class _PdfGoToPageSheetState extends State<PdfGoToPageSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.currentPage}');

  /// The typed page, or null while the field holds nothing usable — which is
  /// what greys the Go button out rather than letting it jump somewhere wrong.
  int? get _target {
    final n = int.tryParse(_controller.text.trim());
    if (n == null || n < 1 || n > widget.totalPages) return null;
    return n;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _target;
    if (t != null) Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final valid = _target != null;

    return Padding(
      // Lifts the sheet clear of the keyboard, which the number pad brings up
      // the moment this opens.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grey3,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  ReaderPdfStrings.pdfGoToPageTitle,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: AppColors.card, shape: BoxShape.circle),
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: AppColors.grey2,
                        size: 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ReaderPdfStrings.pdfGoToPageHint(widget.totalPages),
              style: TextStyle(color: AppColors.grey2, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 2),
                      ),
                      suffixText: '/ ${widget.totalPages}',
                      suffixStyle:
                          TextStyle(color: AppColors.grey3, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: valid ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: Text(
                      ReaderPdfStrings.pdfGoToPageAction,
                      style: TextStyle(
                        color: valid ? Colors.white : AppColors.grey3,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
