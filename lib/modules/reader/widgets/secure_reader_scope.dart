import 'package:flutter/widgets.dart';

import '../../../core/services/screen_protection.dart';

/// Drop into a reader's `Stack`: while it is mounted, screenshots and screen
/// recording are blocked if [bookId] is a subscription-only book (see
/// [ScreenProtection]). Draws nothing.
class SecureReaderScope extends StatefulWidget {
  const SecureReaderScope({super.key, required this.bookId});
  final int bookId;

  @override
  State<SecureReaderScope> createState() => _SecureReaderScopeState();
}

class _SecureReaderScopeState extends State<SecureReaderScope> {
  bool _held = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    ScreenProtection.acquireFor(widget.bookId).then((held) {
      // The reader may have closed before the lookup finished.
      if (_disposed) {
        if (held) ScreenProtection.release();
      } else {
        _held = held;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    if (_held) ScreenProtection.release();
    super.dispose();
  }

  // Sits directly in the readers' Stacks, so it must be a Positioned child: a
  // plain zero-size child would collapse the whole Stack to 0x0.
  @override
  Widget build(BuildContext context) => const Positioned(
      left: 0, top: 0, width: 0, height: 0, child: SizedBox.shrink());
}
