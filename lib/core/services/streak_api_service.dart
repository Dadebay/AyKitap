import 'package:dio/dio.dart';
import '../models/streak.dart';
import '../network/streak_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the real `/streaks/*` endpoints (see the backend's
/// `streak-apis.md` contract). [StreakService] is the single call site —
/// it owns the offline-buffering/retry logic this service itself stays
/// unaware of.
class StreakApiService {
  StreakApiService._();

  /// `POST /streaks/report` — [seconds] is the delta since the last
  /// *successful* report (required), [pages] the page-turn delta over the
  /// same window (omitted entirely when there's nothing to report, since
  /// the backend treats it as optional rather than a literal 0).
  static Future<StreakReportResult> report(
      {required int seconds, int? pages, int? bookId}) async {
    try {
      final response = await DioClient.instance.post(
        StreakEndpoints.streakReport,
        data: {
          'seconds': seconds,
          if (pages != null && pages > 0) 'pages': pages,
          if (bookId != null) 'book_id': bookId,
        },
      );
      return StreakReportResult.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /streaks/me` — backs the whole Streak screen in one call.
  static Future<StreakOverview> getMe() async {
    try {
      final response = await DioClient.instance.get(StreakEndpoints.streakMe);
      return StreakOverview.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /streaks/history` — one page of the daily reading log, newest
  /// first. [limit] is 1..100 server-side (default 30).
  static Future<StreakHistoryPage> getHistory(
      {int page = 1, int limit = 30}) async {
    try {
      final response = await DioClient.instance.get(
          StreakEndpoints.streakHistory,
          queryParameters: {'page': page, 'limit': limit});
      return StreakHistoryPage.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
