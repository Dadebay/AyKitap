import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_activity_api_service.dart';
import 'auth_session.dart';

/// Counts how long the app is actually open in the foreground and reports it
/// to `POST /users/app-activity`, which backs the admin dashboard's "most
/// active users" list.
///
/// Deliberately the cheapest thing that satisfies the contract: **one
/// integer and one timer**. There is no request queue, no retry loop and no
/// background service — a failed report just leaves its seconds in
/// [_pendingMillis], and the next tick carries the running total in a
/// single request. A week offline still costs exactly one integer of memory
/// and sends exactly one request when the connection returns.
///
/// Distinct from [StreakService], which counts *reading* seconds only and
/// runs off the reader screens. This one is app-wide and lives for the
/// process, so it's driven straight from [WidgetsBinding] rather than from
/// any screen's `initState`.
class AppActivityService with WidgetsBindingObserver {
  AppActivityService._();
  static final instance = AppActivityService._();

  /// The contract's mandated cadence. Reporting more often is pointless:
  /// the server drops anything that arrives within 15s of the last report.
  static const _tick = Duration(seconds: 60);

  /// A report closer than this to the previous one is discarded server-side
  /// (it still answers 200). Checked here too so those requests aren't sent
  /// at all — the case this actually avoids is the background flush landing
  /// moments after a routine tick.
  static const _minReportGap = Duration(seconds: 15);

  /// The server rejects anything above this in a single report.
  static const _maxSecondsPerReport = 7200;

  /// With the screen kept awake in the readers, a phone left open on a page
  /// would otherwise keep billing seconds all night. No pointer event for
  /// this long stops the clock until the user touches the screen again.
  static const _idleAfter = Duration(minutes: 10);

  /// The whole of this service's state, per the contract's resource rule.
  ///
  /// Kept in milliseconds rather than seconds so the sub-second remainder
  /// isn't thrown away on every tick — truncating a ~60.4s tick to 60s each
  /// time would quietly lose minutes a day.
  int _pendingMillis = 0;

  Timer? _timer;

  /// Runs only while the app is genuinely being used — foreground *and* not
  /// idle. Using elapsed time rather than counting ticks is what makes the
  /// background flush's partial minute come out right.
  final Stopwatch _active = Stopwatch();
  DateTime _lastInteraction = DateTime.now();
  DateTime? _lastReportAt;
  bool _reporting = false;
  bool _started = false;

  /// Call once from `main()`, after the binding is initialised.
  void init() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _resume();
  }

  /// Any touch anywhere in the app — wired up once in [AykitapApp]'s
  /// `builder`, so it covers every screen including pushed routes. Cheap by
  /// design: it assigns a timestamp and, only when the clock had actually
  /// been stopped for idleness, restarts it.
  void noteInteraction() {
    _lastInteraction = DateTime.now();
    if (_started && _timer != null && !_active.isRunning) _active.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pause();
      case AppLifecycleState.resumed:
        _resume();
      // A transient interruption (notification shade, call banner) isn't
      // backgrounding — same policy the readers' own ping uses.
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _resume() {
    _timer?.cancel();
    _lastInteraction = DateTime.now();
    _active
      ..reset()
      ..start();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  /// Backgrounded: bank the partial minute and send it, then stop counting.
  /// The OS suspends the timer anyway, but stopping it explicitly means no
  /// stray tick can fire during the hand-off.
  void _pause() {
    _timer?.cancel();
    _timer = null;
    _bank();
    _active.stop();
    unawaited(_flush());
  }

  void _onTick() {
    final idle = DateTime.now().difference(_lastInteraction) >= _idleAfter;
    _bank();
    if (idle) {
      // Hold the clock until the next touch. The timer itself keeps running
      // so [noteInteraction] has something to restart against, and the time
      // banked before going idle still gets sent.
      _active.stop();
    }
    unawaited(_flush());
  }

  /// Moves elapsed active time into [_pendingMillis] and restarts the
  /// measurement from zero. `Stopwatch.reset()` leaves the running state
  /// alone, so this is safe whether or not the clock is currently going.
  void _bank() {
    _pendingMillis += _active.elapsedMilliseconds;
    _active.reset();
  }

  Future<void> _flush() async {
    if (_reporting) return;
    final whole = _pendingMillis ~/ 1000;
    if (whole <= 0) return;
    final since = _lastReportAt;
    if (since != null && DateTime.now().difference(since) < _minReportGap)
      return;
    // Anonymous time can't be attributed to anyone — the endpoint is
    // per-user and would just 401. The seconds stay banked, so a session
    // that starts mid-run still gets credited for the time before it.
    if (!await AuthSession.isLoggedIn()) return;

    _reporting = true;
    final sending = whole > _maxSecondsPerReport ? _maxSecondsPerReport : whole;
    try {
      final result = await AppActivityApiService.report(seconds: sending);
      switch (result) {
        case AppActivityDelivery.delivered:
        // Might have been counted; repeating would double it (there is no
        // server-side de-duplication), so these are dropped too.
        case AppActivityDelivery.unknown:
          _pendingMillis -= sending * 1000;
          _lastReportAt = DateTime.now();
        // Never left the device — still ours, the next tick carries them.
        case AppActivityDelivery.notDelivered:
          break;
      }
    } finally {
      _reporting = false;
    }
  }
}
