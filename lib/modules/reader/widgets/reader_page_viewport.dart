import 'package:flutter/material.dart';

/// Keeps one readable page in the middle of a wide tablet window. The height
/// remains fixed so opening and closing the reader controls cannot repaginate
/// EPUB content or move a PDF/CBZ page under the reader's finger.
class ReaderPageViewport extends StatelessWidget {
  const ReaderPageViewport(
      {super.key, required this.child, this.maxWidth = 860});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 700
              ? constraints.maxWidth.clamp(0.0, maxWidth)
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          );
        },
      );
}
