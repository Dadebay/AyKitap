import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_session.dart';
import 'api_config.dart';
import 'api_log_interceptor.dart';

/// The single [Dio] instance every API service in the app sends requests
/// through. Centralised so the base URL, timeouts, and the bearer-token
/// header are each set in exactly one place instead of copy-pasted into
/// every service that needs to call the backend.
class DioClient {
  DioClient._();

  static final Dio instance = _build();

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Attaches the session's bearer token to every request that has one.
    // Endpoints called before login (send-code, verify-login) simply have
    // no token yet, so this is a no-op for them rather than a branch every
    // service would otherwise need to repeat.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthSession.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(const ApiLogInterceptor());
    }

    return dio;
  }
}
