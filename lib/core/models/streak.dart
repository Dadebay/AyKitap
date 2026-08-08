/// One day's reading tally — shared shape for `today`, each `week` entry,
/// and each `GET /streaks/history` item. `goal_met` comes straight from the
/// server (the Ashgabat-day goal check), never recomputed on-device.
class StreakDay {
  final DateTime date;
  final int seconds;
  final int minutes;
  final int pages;
  final bool goalMet;

  const StreakDay({required this.date, required this.seconds, required this.minutes, required this.pages, required this.goalMet});

  factory StreakDay.fromJson(Map<String, dynamic> json) => StreakDay(
        date: DateTime.parse(json['date'] as String),
        seconds: json['seconds'] as int? ?? 0,
        minutes: json['minutes'] as int? ?? 0,
        pages: json['pages'] as int? ?? 0,
        goalMet: json['goal_met'] as bool? ?? false,
      );
}

/// One entry of `GET /streaks/me`'s `week` array — always 7, Monday..Sunday.
class StreakWeekDay extends StreakDay {
  /// 1 (Monday) .. 7 (Sunday), matching `DateTime.weekday`.
  final int weekday;

  const StreakWeekDay({
    required this.weekday,
    required super.date,
    required super.seconds,
    required super.minutes,
    required super.pages,
    required super.goalMet,
  });

  factory StreakWeekDay.fromJson(Map<String, dynamic> json) => StreakWeekDay(
        weekday: json['weekday'] as int,
        date: DateTime.parse(json['date'] as String),
        seconds: json['seconds'] as int? ?? 0,
        minutes: json['minutes'] as int? ?? 0,
        pages: json['pages'] as int? ?? 0,
        goalMet: json['goal_met'] as bool? ?? false,
      );
}

/// One `months.this_month` / `months.last_month` entry of `GET /streaks/me`.
class StreakMonthSummary {
  /// `YYYY-MM`.
  final String month;
  final int pages;
  final int minutes;
  final int daysMet;

  const StreakMonthSummary({required this.month, required this.pages, required this.minutes, required this.daysMet});

  factory StreakMonthSummary.fromJson(Map<String, dynamic> json) => StreakMonthSummary(
        month: json['month'] as String? ?? '',
        pages: json['pages'] as int? ?? 0,
        minutes: json['minutes'] as int? ?? 0,
        daysMet: json['days_met'] as int? ?? 0,
      );
}

enum StreakRewardType { balance, subscription }

StreakRewardType _rewardTypeFromJson(dynamic raw) => raw == 'SUBSCRIPTION' ? StreakRewardType.subscription : StreakRewardType.balance;

/// One `reward_rules` entry of `GET /streaks/me` — what the admin has
/// configured, used to build the info text instead of hard-coding it.
class StreakRewardRule {
  final int dayCount;
  final StreakRewardType rewardType;
  final int? amount;
  final int? monthCount;
  final bool isRepeating;

  const StreakRewardRule({required this.dayCount, required this.rewardType, this.amount, this.monthCount, required this.isRepeating});

  factory StreakRewardRule.fromJson(Map<String, dynamic> json) => StreakRewardRule(
        dayCount: json['day_count'] as int? ?? 0,
        rewardType: _rewardTypeFromJson(json['reward_type']),
        amount: json['amount'] as int?,
        monthCount: json['month_count'] as int?,
        isRepeating: json['is_repeating'] as bool? ?? false,
      );
}

/// One `POST /streaks/report` response's `rewards[]` entry — non-empty only
/// when this report just crossed a reward milestone, and is what triggers
/// the congratulation dialog.
class StreakReward {
  final StreakRewardType rewardType;
  final int? amount;
  final int? monthCount;
  final int streakDay;

  const StreakReward({required this.rewardType, this.amount, this.monthCount, required this.streakDay});

  factory StreakReward.fromJson(Map<String, dynamic> json) => StreakReward(
        rewardType: _rewardTypeFromJson(json['reward_type']),
        amount: json['amount'] as int?,
        monthCount: json['month_count'] as int?,
        streakDay: json['streak_day'] as int? ?? 0,
      );
}

/// `GET /streaks/me` — everything [StreakScreen] needs in one call.
class StreakOverview {
  final int currentStreak;
  final int bestStreak;
  final int goalMinMinutes;
  final StreakDay today;
  final List<StreakWeekDay> week;
  final StreakMonthSummary thisMonth;
  final StreakMonthSummary lastMonth;
  final List<StreakRewardRule> rewardRules;

  const StreakOverview({
    required this.currentStreak,
    required this.bestStreak,
    required this.goalMinMinutes,
    required this.today,
    required this.week,
    required this.thisMonth,
    required this.lastMonth,
    required this.rewardRules,
  });

  factory StreakOverview.fromJson(Map<String, dynamic> json) {
    final months = json['months'] as Map<String, dynamic>? ?? const {};
    return StreakOverview(
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      goalMinMinutes: json['goal_min_minutes'] as int? ?? 15,
      today: StreakDay.fromJson(json['today'] as Map<String, dynamic>),
      week: (json['week'] as List? ?? const []).map((e) => StreakWeekDay.fromJson(e as Map<String, dynamic>)).toList(),
      thisMonth: months['this_month'] != null
          ? StreakMonthSummary.fromJson(months['this_month'] as Map<String, dynamic>)
          : const StreakMonthSummary(month: '', pages: 0, minutes: 0, daysMet: 0),
      lastMonth: months['last_month'] != null
          ? StreakMonthSummary.fromJson(months['last_month'] as Map<String, dynamic>)
          : const StreakMonthSummary(month: '', pages: 0, minutes: 0, daysMet: 0),
      rewardRules: (json['reward_rules'] as List? ?? const []).map((e) => StreakRewardRule.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// `POST /streaks/report`'s response.
class StreakReportResult {
  final StreakDay today;
  final int currentStreak;
  final int bestStreak;
  final List<StreakReward> rewards;

  const StreakReportResult({required this.today, required this.currentStreak, required this.bestStreak, required this.rewards});

  factory StreakReportResult.fromJson(Map<String, dynamic> json) => StreakReportResult(
        today: StreakDay.fromJson(json['today'] as Map<String, dynamic>),
        currentStreak: json['current_streak'] as int? ?? 0,
        bestStreak: json['best_streak'] as int? ?? 0,
        rewards: (json['rewards'] as List? ?? const []).map((e) => StreakReward.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// One page of `GET /streaks/history`.
class StreakHistoryPage {
  final int total;
  final int page;
  final int limit;
  final List<StreakDay> items;

  const StreakHistoryPage({required this.total, required this.page, required this.limit, required this.items});

  factory StreakHistoryPage.fromJson(Map<String, dynamic> json) => StreakHistoryPage(
        total: json['total'] as int? ?? 0,
        page: json['page'] as int? ?? 1,
        limit: json['limit'] as int? ?? 30,
        items: (json['items'] as List? ?? const []).map((e) => StreakDay.fromJson(e as Map<String, dynamic>)).toList(),
      );

  bool get hasMore => page * limit < total;
}
