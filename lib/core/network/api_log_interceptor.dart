import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// ANSI colour codes — most terminals `flutter run` prints into (VS Code's,
/// Android Studio's, and a plain terminal alike) render these, so a request
/// jumps out from the wall of platform log noise around it instead of
/// blending in as one more grey line.
enum _AnsiColor {
  cyan('\x1B[36m'), // outgoing request
  green('\x1B[32m'), // 2xx response
  yellow('\x1B[33m'), // non-2xx response
  red('\x1B[31m'); // network/timeout failure, no response at all

  final String code;
  const _AnsiColor(this.code);
}

const _ansiReset = '\x1B[0m';
const _ansiBold = '\x1B[1m';

/// Opt-in, debug-only API timing diagnostics.
///
/// This deliberately logs metadata only: method, path, status/error category,
/// and elapsed time. Headers, query strings, request/response bodies, hostnames,
/// and exception messages can all contain personal data or credentials and are
/// therefore never formatted or printed here.
class ApiLogInterceptor extends Interceptor {
  const ApiLogInterceptor();

  static const _startedAtKey = '_apiLogStartedAtMicros';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;
    debugPrint(
      '${_AnsiColor.cyan.code}$_ansiBold→ ${options.method} ${_path(options)}$_ansiReset',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final ok =
        (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    final color = ok ? _AnsiColor.green : _AnsiColor.yellow;
    final options = response.requestOptions;
    debugPrint(
      '${color.code}$_ansiBold← ${response.statusCode ?? 'unknown'} '
      '${options.method} ${_path(options)} (${_elapsedMs(options)}ms)$_ansiReset',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final outcome = err.response?.statusCode?.toString() ?? _errorCategory(err);
    debugPrint(
      '${_AnsiColor.red.code}$_ansiBold✕ ${options.method} ${_path(options)} '
      '$outcome (${_elapsedMs(options)}ms)$_ansiReset',
    );
    handler.next(err);
  }

  static String _path(RequestOptions options) {
    final path = options.uri.path;
    return path.isEmpty ? '/' : path;
  }

  static int _elapsedMs(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! int) return 0;
    final elapsedMicros = DateTime.now().microsecondsSinceEpoch - startedAt;
    return elapsedMicros <= 0 ? 0 : elapsedMicros ~/ 1000;
  }

  static String _errorCategory(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'timeout',
      DioExceptionType.connectionError => 'network_error',
      DioExceptionType.cancel => 'cancelled',
      DioExceptionType.badCertificate => 'bad_certificate',
      DioExceptionType.badResponse => 'bad_response',
      DioExceptionType.unknown => 'unknown_error',
    };
  }
}
