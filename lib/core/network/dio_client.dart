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
          unawaited(SessionExpiryHandler.instance.handleUnauthorized(
            path: err.requestOptions.path,
            host: err.requestOptions.baseUrl,
          ));
        }
        // `ApiConfig.baseUrl` is a domain that doesn't resolve on every
        // network (see its doc comment) — on a connection failure, retry
        // once against the build-time [ApiConfig.fallbackBaseUrl] instead of
        // failing outright. Guarded by `_retriedFallbackHost` so a failure
        // from the fallback itself doesn't loop. Builds without a configured
        // fallback simply retain the primary-host behavior.
        final options = err.requestOptions;
        if (shouldRetryOnFallbackHost(err) &&
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

    // Which origin this build will actually talk to, said once at startup.
    // It earns its own line because a failing request can't tell you: the
    // same primary host failing behaves completely differently depending on
    // whether `API_FALLBACK_BASE_URL` was defined for *this* build, and one
    // platform silently recovering while another doesn't looks like a bug in
    // the app rather than a difference in how each was launched.
    //
    // The fallback's value is deliberately not printed — it is kept out of
    // source control on purpose (see [ApiConfig.fallbackBaseUrl]), and
    // whether one exists is the part that actually aids debugging.
    if (kDebugMode) {
      debugPrint('🌐 API base=${ApiConfig.baseUrl} '
          'fallback=${ApiConfig.hasFallbackBaseUrl ? 'configured' : 'none'}');
    }

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

/// Whether [DioClient] should retry this failure against
/// [ApiConfig.fallbackBaseUrl].
///
/// The test is "did this request ever reach a server?", not the exception
/// type on its own. Dio reports a `SocketException` as
/// [DioExceptionType.connectionError], but a TLS connection the *platform*
/// refuses arrives as [DioExceptionType.unknown] carrying a
/// `HandshakeException` and a null message — and iOS refuses connections
/// Android accepts (stricter chain validation, and App Transport Security on
/// top of it). Keying only off `connectionError`/`connectionTimeout` meant
/// the fallback was skipped for precisely the platform-specific failures it
/// was added to cover, so the primary host failing took the whole app down
/// on one platform while the other quietly fell back and looked fine.
///
/// A failure that *did* carry a response is deliberately excluded: the host
/// answered, so the problem is with the request or the server, and retrying
/// it against a different origin would only obscure that.
@visibleForTesting
bool shouldRetryOnFallbackHost(DioException e) =>
    e.response == null &&
    (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown);

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
