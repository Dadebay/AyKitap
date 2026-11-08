import 'dart:async';

import '../../../core/services/streak_service.dart';

/// Active-reading streak ping (streak-apis.md: report every 60s while
/// actively reading, plus once on pause/background/close with the residual
/// seconds since the last tick), shared verbatim across the EPUB, PDF and
/// CBZ readers — each one owns its own instance for the lifetime of its
/// screen and drives it from `initState`/`didChangeAppLifecycleState`/
/// `dispose`.
///
/// Previously duplicated three times (once per reader); pulled out here so
/// the timer/stopwatch bookkeeping — and the residual-flush-must-reset-or-
/// it-double-reports subtlety below — has exactly one implementation to get
/// right.
class ReaderStreakPing {
  static const _interval = Duration(seconds: 60);

  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  /// Starts (or restarts) the periodic ping. Call once when the reader opens
  /// and again on every `AppLifecycleState.resumed`.
  void start() {
    _timer?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer.periodic(_interval, (_) {
      StreakService.instance.recordActiveSeconds(_interval.inSeconds);
      _stopwatch.reset();
    });
  }

  /// Sends whatever active-reading time has elapsed since the last periodic
  /// tick (0 if the timer never fired yet) — call on pause/background/close
  /// so a reading burst shorter than [_interval] still counts instead of
  /// being silently dropped when the timer stops.
  ///
  /// Resets (not just stops) the stopwatch so a second flush call — a screen
  /// closing normally calls this once to save-and-close and once more from
  /// its own `dispose` as a safety net — reads 0 instead of re-sending the
  /// same already-flushed residual.
  void flushResidual() {
    _timer?.cancel();
    final residual = _stopwatch.elapsed.inSeconds;
    _stopwatch
      ..stop()
      ..reset();
    if (residual > 0) StreakService.instance.flushResidual(seconds: residual);
  }
}
