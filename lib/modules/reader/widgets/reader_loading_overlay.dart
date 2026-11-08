import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// The plain "book_reading_boy" loading animation plus a status line, shown
/// full-screen while the PDF/CBZ readers unpack or open their file. Distinct
/// from [BookOpeningOverlay] (the EPUB reader's animated 0→100% ramp) —
/// PDF/CBZ extraction exposes no comparable progress to ramp toward, so this
/// is the simpler, static version the two of them used to duplicate inline.
class ReaderLoadingOverlay extends StatelessWidget {
  final Color backgroundColor;
  final bool isDarkSurface;
  final String message;

  const ReaderLoadingOverlay({
    super.key,
    required this.backgroundColor,
    required this.isDarkSurface,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: backgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Lottie.asset(
                  'assets/animations/book_reading_boy.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                message,
                style: TextStyle(
                  color: isDarkSurface ? Colors.white70 : Colors.black54,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
