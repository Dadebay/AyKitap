import 'package:flutter/material.dart';

/// The "N / total" page readout shown at the bottom of the screen while the
/// reader's chrome is hidden (focus mode) — shared by the PDF and CBZ
/// readers, which used to carry an identical inline copy.
class ReaderFocusPageIndicator extends StatelessWidget {
  final bool visible;
  final Color color;
  final String label;

  const ReaderFocusPageIndicator({
    super.key,
    required this.visible,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
