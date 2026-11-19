import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/services/streak_service.dart';
import '../../../core/services/daily_reading_goal_service.dart';
import 'read_pages_today.dart';

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
  /// [pageDwell]: how long a page must stay on screen, uninterrupted, before
  /// it counts as read — see [onPage]. Text readers use the default; comics
  /// pass a shorter one.
  ReaderStreakPing({this.pageDwell = const Duration(seconds: 10)});

  static const _interval = Duration(seconds: 60);
  final Duration pageDwell;

  Timer? _timer;

  // Page-dwell counting. A page counts only after staying on screen for
  // [pageDwell]; every page change restarts the wait, so flicking through
  // pages, dragging the scrubber or jumping to a place counts nothing until
  // the reader actually stops somewhere. Each page counts once per day
  // ([ReadPagesToday]).
  Timer? _dwellTimer;
  int? _dwellPage;
  int? _dwellBook;
  bool _paused = false;
  final Stopwatch _stopwatch = Stopwatch();
  final Stopwatch _goalStopwatch = Stopwatch();

  /// Starts (or restarts) the periodic ping. Call once when the reader opens
  /// and again on every `AppLifecycleState.resumed`.
  void start() {
    _paused = false;
    _armDwell();
    _timer?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _goalStopwatch.reset();
    if (_dwellPage != null) _goalStopwatch.start();
    _timer = Timer.periodic(_interval, (_) {
      // Timers can fire late while the UI isolate is busy turning a page.
      // Report measured foreground time, not a fixed minute per callback.
      final elapsed = _stopwatch.elapsed.inSeconds;
      _stopwatch.reset();
      if (elapsed > 0) StreakService.instance.recordActiveSeconds(elapsed);
      final goalElapsed = _goalStopwatch.elapsed.inSeconds;
      _goalStopwatch.reset();
      if (goalElapsed > 0) {
        _goalStopwatch.start();
        unawaited(DailyReadingGoalService.instance.record(goalElapsed));
      }
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
    _paused = true;
    _dwellTimer?.cancel();
    _timer?.cancel();
    final residual = _stopwatch.elapsed.inSeconds;
    final goalResidual = _goalStopwatch.elapsed.inSeconds;
    _goalStopwatch
      ..stop()
      ..reset();
    _stopwatch
      ..stop()
      ..reset();
    if (residual > 0) StreakService.instance.flushResidual(seconds: residual);
    if (goalResidual > 0) {
      unawaited(DailyReadingGoalService.instance.record(goalResidual));
    }
  }

  /// The reader is now on [page] of [bookKey]. Restarts the wait; if the
  /// reader is still on it after [pageDwell] (and the app is in the
  /// foreground), the page is counted as read.
  void onPage(int page, {required int bookKey}) {
    if (_dwellBook == bookKey && _dwellPage == page) return;
    _dwellPage = page;
    _dwellBook = bookKey;
    if (!_paused && !_goalStopwatch.isRunning) _goalStopwatch.start();
    _armDwell();
  }

  void _armDwell() {
    _dwellTimer?.cancel();
    final page = _dwellPage;
    final book = _dwellBook;
    if (_paused || page == null || book == null) return;
    _dwellTimer = Timer(pageDwell, () async {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      if (await ReadPagesToday.markIfNew(book, page)) {
        StreakService.instance.recordPageRead();
      }
    });
  }
}
