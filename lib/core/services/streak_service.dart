import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local stand-in for the server-computed reading streak (TZ section 9).
/// The spec has the *server* tally active-reading seconds from a 30-second
/// client ping and decide streaks/rewards from that; this project has no
/// backend, so [ReaderProvider] plays the pinger and this singleton plays
/// the server — same cadence and thresholds (§9.1), persisted on-device.
class StreakService extends ChangeNotifier {
  StreakService._();
  static final instance = StreakService._();

  static const _kDailyLog = 'streak_daily_log_v1';
  static const _kDailyPages = 'streak_daily_pages_v1';
  static const _kCurrentStreak = 'streak_current_v1';
  static const _kBestStreak = 'streak_best_v1';
  static const _kLastStreakDate = 'streak_last_date_v1';
  static const _kBalanceManat = 'streak_balance_manat_v1';
  static const _kRewardedAtStreak = 'streak_rewarded_at_v1';

  static const dailyGoalSeconds = 15 * 60;
  static const _rewardIntervalDays = 30;
  static const _rewardManat = 10;
  // 70, not 60: the monthly breakdown ([pagesInMonth]) needs "last calendar
  // month" fully intact no matter what day it is today — worst case (today
  // is the 1st) that's a 31-day month plus today, i.e. 62 days back.
  static const _logRetentionDays = 70;

  Map<String, int> _dailyLog = {};
  Map<String, int> _dailyPages = {};
  int _currentStreak = 0;
  int _bestStreak = 0;
  DateTime? _lastStreakDate;
  int _balanceManat = 45; // seeded to match the profile screen's old mock value
  int _rewardedAtStreak = 0;

  bool _loaded = false;

  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get balanceManat => _balanceManat;
  int get todaySeconds => _dailyLog[_dateKey(DateTime.now())] ?? 0;
  int get todayPages => _dailyPages[_dateKey(DateTime.now())] ?? 0;

  /// Per-day reading log (pages + minutes), most recent day first — only
  /// days with some recorded activity, for the streak screen's history list.
  List<StreakDayLog> get history {
    final keys = {..._dailyLog.keys, ..._dailyPages.keys}.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map((k) => StreakDayLog(date: DateTime.parse(k), seconds: _dailyLog[k] ?? 0, pages: _dailyPages[k] ?? 0))
        .where((e) => e.seconds > 0 || e.pages > 0)
        .toList();
  }

  /// Total pages turned within the calendar month containing [month] (only
  /// its year/month matter, not the day). Backs the "this month / last
  /// month" toggle on the streak screen.
  int pagesInMonth(DateTime month) {
    var total = 0;
    _dailyPages.forEach((k, pages) {
      final d = DateTime.parse(k);
      if (d.year == month.year && d.month == month.month) total += pages;
    });
    return total;
  }

  /// Total minutes read within the calendar month containing [month] — same
  /// month-matching as [pagesInMonth], off [_dailyLog] instead of pages.
  int minutesInMonth(DateTime month) {
    var totalSeconds = 0;
    _dailyLog.forEach((k, seconds) {
      final d = DateTime.parse(k);
      if (d.year == month.year && d.month == month.month) totalSeconds += seconds;
    });
    return totalSeconds ~/ 60;
  }

  /// Mon..Sun read/not-read for the current calendar week — feeds the week
  /// grid on ProfileScreen and StreakScreen (§9.2).
  List<bool> get weekRead {
    final today = _dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(today)) return false;
      return (_dailyLog[_dateKey(day)] ?? 0) >= dailyGoalSeconds;
    });
  }

  Future<void> load() async {
    if (_loaded) return;
    await _ensureLoaded();
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final rawLog = prefs.getString(_kDailyLog);
    if (rawLog != null) {
      final decoded = jsonDecode(rawLog) as Map<String, dynamic>;
      _dailyLog = decoded.map((k, v) => MapEntry(k, v as int));
    }
    final rawPages = prefs.getString(_kDailyPages);
    if (rawPages != null) {
      final decoded = jsonDecode(rawPages) as Map<String, dynamic>;
      _dailyPages = decoded.map((k, v) => MapEntry(k, v as int));
    }
    _currentStreak = prefs.getInt(_kCurrentStreak) ?? 0;
    _bestStreak = prefs.getInt(_kBestStreak) ?? 0;
    _balanceManat = prefs.getInt(_kBalanceManat) ?? 45;
    _rewardedAtStreak = prefs.getInt(_kRewardedAtStreak) ?? 0;
    final lastDateStr = prefs.getString(_kLastStreakDate);
    _lastStreakDate = lastDateStr != null ? DateTime.parse(lastDateStr) : null;

    _pruneOldEntries();

    // A full day passed with no qualifying reading since the last counted
    // day → the streak is broken: "bir gün okalmasa, streak 0-dan başlaýar".
    final today = _dateOnly(DateTime.now());
    var changed = false;
    if (_lastStreakDate != null && today.difference(_lastStreakDate!).inDays > 1 && _currentStreak != 0) {
      _currentStreak = 0;
      changed = true;
    }

    _loaded = true;
    if (changed) await _persist();
  }

  /// Records [seconds] of active reading against today's tally — the local
  /// analog of the spec's 30-second server ping. Recomputes the streak once
  /// today crosses the 15-minute goal, and pays out every 30-day milestone.
  Future<void> recordActiveSeconds(int seconds) async {
    if (seconds <= 0) return;
    await _ensureLoaded();

    final today = _dateOnly(DateTime.now());
    final key = _dateKey(today);
    final metGoalBefore = (_dailyLog[key] ?? 0) >= dailyGoalSeconds;
    _dailyLog[key] = (_dailyLog[key] ?? 0) + seconds;
    final metGoalNow = _dailyLog[key]! >= dailyGoalSeconds;

    if (metGoalNow && !metGoalBefore) {
      final yesterday = today.subtract(const Duration(days: 1));
      _currentStreak = (_lastStreakDate == yesterday) ? _currentStreak + 1 : 1;
      _lastStreakDate = today;
      if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;

      if (_currentStreak % _rewardIntervalDays == 0 && _currentStreak != _rewardedAtStreak) {
        _balanceManat += _rewardManat;
        _rewardedAtStreak = _currentStreak;
      }
    }

    _pruneOldEntries();
    await _persist();
    notifyListeners();
  }

  /// Deducts [manat] from the on-device balance for a book purchase, if the
  /// balance covers it. Returns true on success, false if funds are short —
  /// the caller then sends the user to top up. Mirrors the server-side
  /// balance debit the real backend will do (§10.2 satyn alyş logikasy).
  Future<bool> spendBalance(int manat) async {
    if (manat <= 0) return true;
    await _ensureLoaded();
    if (_balanceManat < manat) return false;
    _balanceManat -= manat;
    await _persist();
    notifyListeners();
    return true;
  }

  /// Tallies [count] pages turned today — feeds the "kaç sahypa okadyňyz"
  /// history on the streak screen. Purely a reading-activity log; it has no
  /// effect on the streak or balance, which are driven by [recordActiveSeconds].
  Future<void> recordPageRead({int count = 1}) async {
    if (count <= 0) return;
    await _ensureLoaded();
    final key = _dateKey(_dateOnly(DateTime.now()));
    _dailyPages[key] = (_dailyPages[key] ?? 0) + count;
    _pruneOldEntries();
    await _persist();
    notifyListeners();
  }

  void _pruneOldEntries() {
    final cutoff = _dateOnly(DateTime.now()).subtract(const Duration(days: _logRetentionDays));
    _dailyLog.removeWhere((k, _) => DateTime.parse(k).isBefore(cutoff));
    _dailyPages.removeWhere((k, _) => DateTime.parse(k).isBefore(cutoff));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDailyLog, jsonEncode(_dailyLog));
    await prefs.setString(_kDailyPages, jsonEncode(_dailyPages));
    await prefs.setInt(_kCurrentStreak, _currentStreak);
    await prefs.setInt(_kBestStreak, _bestStreak);
    await prefs.setInt(_kBalanceManat, _balanceManat);
    await prefs.setInt(_kRewardedAtStreak, _rewardedAtStreak);
    if (_lastStreakDate != null) {
      await prefs.setString(_kLastStreakDate, _dateKey(_lastStreakDate!));
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// One day's entry in the reading history: pages turned + minutes read.
class StreakDayLog {
  final DateTime date;
  final int seconds;
  final int pages;
  const StreakDayLog({required this.date, required this.seconds, required this.pages});

  int get minutes => seconds ~/ 60;
  bool get metGoal => seconds >= StreakService.dailyGoalSeconds;
}
