import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

/// Full-screen "couldn't open this file" state, shared by the PDF and CBZ
/// readers — both used to carry an identical inline copy of this icon +
/// message layout.
class ReaderErrorOverlay extends StatelessWidget {
  final Color backgroundColor;
  final bool isDarkSurface;
  final String message;

  const ReaderErrorOverlay({
    super.key,
    required this.backgroundColor,
    required this.isDarkSurface,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    return Positioned.fill(
      child: ColoredBox(
        color: backgroundColor,
        child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: tablet ? 88 : 64,
                      height: tablet ? 88 : 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedFileNotFound,
                          color: AppColors.primary,
                          size: tablet ? 38 : 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkSurface ? Colors.white70 : Colors.black54,
                        fontSize: tablet ? 16 : 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
