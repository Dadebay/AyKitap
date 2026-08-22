/// Reading-streak endpoints — [StreakApiService]. Split out of the former
/// single `api_endpoints.dart` by which service owns each route. Paths are
/// relative to [ApiConfig.baseUrl].
class StreakEndpoints {
  StreakEndpoints._();

  /// POST — reports reading activity (`seconds`/`pages` deltas since the
  /// last successful report) toward today's streak goal. Call every 60s
  /// during active reading, plus once on pause/background/close with the
  /// residual seconds. The server credits whatever it receives to the
  /// Ashgabat calendar day *at the moment it's received* — no back-dating,
  /// so a report that had to be buffered offline should be flushed as soon
  /// as the connection returns rather than held any longer.
  static const String streakReport = '/streaks/report';

  /// GET — everything the Streak screen needs in one call: today/week/month
  /// totals, streak counts, and the reward rules (so their text isn't
  /// hard-coded on-device).
  static const String streakMe = '/streaks/me';

  /// GET — paginated daily reading history (`?page=&limit=`), newest day
  /// first.
  static const String streakHistory = '/streaks/history';
}
