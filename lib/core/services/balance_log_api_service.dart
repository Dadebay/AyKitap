import 'package:dio/dio.dart';
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
      final logs = data
          .map((item) => BalanceLog.fromJson(item as Map<String, dynamic>))
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return removeMirroredIncomingGiftLogs(logs);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
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
