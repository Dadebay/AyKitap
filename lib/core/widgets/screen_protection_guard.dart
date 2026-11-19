import 'package:flutter/widgets.dart';

import '../services/screen_protection.dart';

/// Wraps a screen: while [enabled] is true, screenshots and screen recording
/// are blocked (see [ScreenProtection]). Unlike `SecureReaderScope` it wraps
/// a [child] instead of sitting in a `Stack`, and [enabled] may flip after the
/// first build — e.g. once a detail page has loaded the book and learned that
/// it is subscription-only.
class ScreenProtectionGuard extends StatefulWidget {
  const ScreenProtectionGuard({
    super.key,
    required this.enabled,
    required this.bookId,
    required this.child,
  });

  final bool enabled;
  final int bookId;
  final Widget child;

  @override
  State<ScreenProtectionGuard> createState() => _ScreenProtectionGuardState();
}

class _ScreenProtectionGuardState extends State<ScreenProtectionGuard> {
  bool _held = false;
  bool _disposed = false;
  bool _acquiring = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ScreenProtectionGuard old) {
    super.didUpdateWidget(old);
    _sync();
  }

  Future<void> _sync() async {
    if (widget.enabled && !_held && !_acquiring) {
      _acquiring = true;
      final held =
          await ScreenProtection.acquireFor(widget.bookId, force: true);
      _acquiring = false;
      if (_disposed) {
        if (held) ScreenProtection.release();
      } else {
        _held = held;
        // Turned off while the lookup was in flight.
        if (!widget.enabled) _sync();
      }
    } else if (!widget.enabled && _held) {
      _held = false;
      ScreenProtection.release();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_held) ScreenProtection.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
