import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import '../localization/strings/reader_strings.dart';
import '../theme/app_colors.dart';

/// Shown when someone tries to screenshot / record a subscription-only book.
///
/// Built from plain widgets (no Material dependency) so it renders the same
/// whichever Material library the host screen uses.
class ScreenshotBlockedDialog extends StatelessWidget {
  const ScreenshotBlockedDialog({super.key});

  static bool _open = false;

  /// Shows the dialog over everything; a second attempt while it is already
  /// on screen is ignored instead of stacking another one.
  static Future<void> show(BuildContext context) async {
    if (_open) {
      debugPrint('🔒 ScreenshotBlockedDialog: already open, ignored');
      return;
    }
    _open = true;
    debugPrint('🔒 ScreenshotBlockedDialog: DIALOG shown');
    HapticFeedback.mediumImpact();
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: ReaderStrings.screenshotDialogOk,
        barrierColor: const Color(0xB3000000),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const ScreenshotBlockedDialog(),
        transitionBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(scale: Tween<double>(begin: 0.86, end: 1).animate(curved), child: child),
          );
        },
      );
    } finally {
      _open = false;
    }
  }

  static const _red = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _red.withValues(alpha: 0.28)),
                boxShadow: [
                  BoxShadow(color: _red.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: 2),
                  const BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ShieldBadge(),
                  const SizedBox(height: 22),
                  Text(
                    ReaderStrings.screenshotDialogTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ReaderStrings.screenshotDialogBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.grey2,
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedCopyright, color: _red, size: 17),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            ReaderStrings.screenshotDialogNote,
                            style: TextStyle(
                              color: AppColors.grey1,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Text(
                        ReaderStrings.screenshotDialogOk,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A shield with a camera-off glyph, ringed by soft concentric glows.
class _ShieldBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const red = ScreenshotBlockedDialog._red;
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 112, height: 112, decoration: BoxDecoration(shape: BoxShape.circle, color: red.withValues(alpha: 0.07))),
          Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, color: red.withValues(alpha: 0.13))),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B6B), Color(0xFFE5484D)],
              ),
              boxShadow: [
                BoxShadow(color: Color(0x66E5484D), blurRadius: 18),
              ],
            ),
            child: const Center(
              child: HugeIcon(icon: HugeIcons.strokeRoundedCameraOff01, color: Color(0xFFFFFFFF), size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
