import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A device-local reading goal aligned with the streak's 15-minute default.
/// The backend remains authoritative for granting the streak and rewards.
class DailyReadingGoalService extends ChangeNotifier {
  DailyReadingGoalService._();
  static final instance = DailyReadingGoalService._();

  static const targetSeconds = 15 * 60;
  static const _dayKey = 'daily_reading_goal_day';
  static const _secondsKey = 'daily_reading_goal_seconds';

  String? _day;
  int _seconds = 0;
  Future<void>? _loadFuture;
  Future<void> _write = Future.value();

  int get secondsToday {
    return _day == _today() ? _seconds : 0;
  }

  double get progress => (secondsToday / targetSeconds).clamp(0.0, 1.0);
  bool get completed => secondsToday >= targetSeconds;

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _rollDay() {
    final day = _today();
    if (_day == day) return;
    _day = day;
    _seconds = 0;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final day = _today();
    _day = day;
    _seconds =
        prefs.getString(_dayKey) == day ? prefs.getInt(_secondsKey) ?? 0 : 0;
    notifyListeners();
  }

  Future<void> record(int seconds) async {
    if (seconds <= 0) return;
    await load();
    _rollDay();
    _seconds += seconds;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() {
    final day = _day;
    final seconds = _seconds;
    _write = _write.catchError((_) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dayKey, day ?? _today());
      await prefs.setInt(_secondsKey, seconds);
    });
    return _write;
  }
}
