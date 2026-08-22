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
      return logs;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
