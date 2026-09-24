import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/balance_log.dart';
import '../network/account_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Fetches the signed-in user's top-up and purchase activity.
class BalanceLogApiService {
  BalanceLogApiService._();

  static Future<List<BalanceLog>> listLogs() async {
    try {
      final response =
          await DioClient.instance.get(AccountEndpoints.balanceLogs);
      final data = response.data['data'] as List;
      _debugLog('server returned ${data.length} row(s)');
      final logs = data
          .map((item) => BalanceLog.fromJson(item as Map<String, dynamic>))
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final log in logs) {
        _debugLog('  • id=${log.id} ${log.event} ${log.amount} TMT '
            '${log.createdAt.toIso8601String()}');
      }
      final visible = removeMirroredIncomingGiftLogs(logs);
      final hidden = logs.length - visible.length;
      _debugLog('showing ${visible.length} row(s)'
          '${hidden > 0 ? ' ($hidden hidden as a mirrored sent-gift row)' : ''}');
      return visible;
    } on DioException catch (e) {
      _debugLog('load failed: status=${e.response?.statusCode} '
          'body=${e.response?.data}');
      throw ApiException.fromDioException(e);
    }
  }

  /// Temporary, for diagnosing why a gift *received* from another reader
  /// isn't appearing in this list. Prints what the endpoint actually returns
  /// for the signed-in account, and what this class then hides — the two
  /// things a screenshot of the page can't tell apart. Debug builds only,
  /// and only this account's own rows: no token, no phone number.
  static void _debugLog(String message) {
    if (kDebugMode) debugPrint('💰 BalanceLogs: $message');
  }
}

/// The current backend writes both transfer rows to the sender. Suppress only
/// the mirrored incoming row: same amount, adjacent id, and nearly identical
/// timestamp. A real incoming gift without that matching sent row is kept.
List<BalanceLog> removeMirroredIncomingGiftLogs(List<BalanceLog> logs) {
  return logs.where((log) {
    if (log.event.toUpperCase() != 'COME_FROM_FRIEND') return true;

    final hasMatchingSentGift = logs.any((candidate) {
      if (candidate.event.toUpperCase() != 'SEND_TO_FRIEND' ||
          candidate.amount != log.amount ||
          candidate.id + 1 != log.id) {
        return false;
      }
      return log.createdAt.difference(candidate.createdAt).abs() <=
          const Duration(seconds: 10);
    });
    return !hasMatchingSentGift;
  }).toList();
}
