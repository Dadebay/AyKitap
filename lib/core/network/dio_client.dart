import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../localization/app_locale.dart';
import '../services/auth_session.dart';
import '../services/session_expiry_handler.dart';
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
    //
    // `Accept-Language` rides along here for the same reason: the backend
    // returns book titles, genres, and the rest in whichever of tk/ru/tr it
    // is asked for, and it has to follow the in-app language switch rather
    // than the device's. Read per request — not once at build time — so a
    // language change takes effect on the very next call.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['Accept-Language'] = AppLocale.instance.current.name;
        final token = await AuthSession.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      // A 401 here means the backend no longer honors this device's
      // token ("Session expired or revoked", or any other authenticated
      // call rejected the same way) — every other authenticated request
      // would otherwise keep failing the same way with no way for the user
      // to tell why. Fire-and-forget: the error still propagates as
      // [ApiException] to whichever call site was awaiting it, same as
      // before — this only adds the session-recovery side effect.
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          unawaited(SessionExpiryHandler.instance.handleUnauthorized());
        }
        // `ApiConfig.baseUrl` is a domain that doesn't resolve on every
        // network (see its doc comment) — on a connection failure, retry
        // once against the build-time [ApiConfig.fallbackBaseUrl] instead of
        // failing outright. Guarded by `_retriedFallbackHost` so a failure
        // from the fallback itself doesn't loop. Builds without a configured
        // fallback simply retain the primary-host behavior.
        final options = err.requestOptions;
        final isConnectionFailure =
            err.type == DioExceptionType.connectionError ||
                err.type == DioExceptionType.connectionTimeout;
        if (isConnectionFailure &&
            ApiConfig.hasFallbackBaseUrl &&
            options.extra['_retriedFallbackHost'] != true) {
          options.extra['_retriedFallbackHost'] = true;
          options.baseUrl = ApiConfig.fallbackBaseUrl;
          try {
            final response = await dio.fetch(options);
            handler.resolve(response);
            return;
          } on DioException catch (retryErr) {
            handler.next(retryErr);
            return;
          }
        }
        handler.next(err);
      },
    ));

    const apiLoggingRequested = bool.fromEnvironment('API_LOGGING');
    if (shouldAttachApiLogInterceptor(
      isDebugMode: kDebugMode,
      requested: apiLoggingRequested,
    )) {
      dio.interceptors.add(const ApiLogInterceptor());
    }

    return dio;
  }
}

/// API traffic is silent by default, including in debug builds. Developers can
/// opt into the metadata-only [ApiLogInterceptor] with
/// `--dart-define=API_LOGGING=true`; profile and release builds stay silent even
/// when that flag is accidentally present.
@visibleForTesting
bool shouldAttachApiLogInterceptor({
  required bool isDebugMode,
  required bool requested,
}) =>
    isDebugMode && requested;
