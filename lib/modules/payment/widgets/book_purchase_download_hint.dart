import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';

/// Website hand-off for readers who want the purchased file outside the app.
///
/// Deliberately quiet: a plain card like the purchase screen's other cards,
/// with the address as the only accent. It dips slightly under the finger so
/// the whole card reads as one button.
class BookPurchaseDownloadHint extends StatefulWidget {
  const BookPurchaseDownloadHint({super.key});

  @override
  State<BookPurchaseDownloadHint> createState() =>
      _BookPurchaseDownloadHintState();
}

class _BookPurchaseDownloadHintState extends State<BookPurchaseDownloadHint> {
  static final _website =
      Uri.parse('https://${PaymentStrings.downloadFileWebsite}');

  bool _pressed = false;

  Future<void> _openWebsite() async {
    try {
      final opened = await launchUrl(
        _website,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) _showError();
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (!mounted) return;
    context.showAppSnackBar(
      PaymentStrings.downloadFileWebsiteOpenError,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      link: true,
      label: PaymentStrings.downloadFileWebsiteText,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.card,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: _openWebsite,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _iconTile(),
                  const SizedBox(width: 12),
                  Expanded(child: _message()),
                  const SizedBox(width: 8),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowUpRight01,
                    color: AppColors.grey2,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconTile() => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedDownload01,
            color: AppColors.primary,
            size: 19,
          ),
        ),
      );

  /// The sentence, with the address set as a soft pill. A [Wrap] rather than
  /// one line of text: on a narrow screen or in a longer language the pieces
  /// drop onto the next line instead of overflowing.
  Widget _message() {
    final style = TextStyle(
      color: AppColors.grey2,
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      height: 1.3,
    );
    final suffix = PaymentStrings.downloadFileWebsiteSuffix.trim();
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(PaymentStrings.downloadFileWebsitePrefix, style: style),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            PaymentStrings.downloadFileWebsite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        if (suffix.isNotEmpty) Text(suffix, style: style),
      ],
    );
  }
}
