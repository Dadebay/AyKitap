import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// ANSI colour codes — most terminals `flutter run` prints into (VS Code's,
/// Android Studio's, and a plain terminal alike) render these, so a request
/// jumps out from the wall of platform log noise around it instead of
/// blending in as one more grey line.
enum _AnsiColor {
  cyan('\x1B[36m'), // outgoing request
  green('\x1B[32m'), // 2xx response
  yellow('\x1B[33m'), // non-2xx response with a body (e.g. validation errors)
  red('\x1B[31m'); // network/timeout failure, no response at all

  final String code;
  const _AnsiColor(this.code);
}

const _ansiReset = '\x1B[0m';
const _ansiBold = '\x1B[1m';

/// Prints every request/response through [DioClient] as one coloured block —
/// method + path in the request's colour, status + body on the line under
/// it — so testing the auth endpoints against the real backend means reading
/// the terminal, not stepping through with a debugger. Debug builds only:
/// this is a development aid, not something that should ship.
class ApiLogInterceptor extends Interceptor {
  const ApiLogInterceptor();

  /// The catalogue response can contain many books with long descriptions;
  /// logging its formatted body overwhelms the debug console. Keep logging
  /// every other endpoint normally.
  static bool _shouldSkipResponseBody(RequestOptions options) =>
      options.path == '/books/all';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer()
      ..writeln(
          '${_AnsiColor.cyan.code}$_ansiBold→ ${options.method} ${options.uri}$_ansiReset');
    if (options.data != null) {
      buffer.writeln(
          '${_AnsiColor.cyan.code}  body: ${_prettyJson(options.data)}$_ansiReset');
    }
    debugPrint(buffer.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldSkipResponseBody(response.requestOptions)) {
      handler.next(response);
      return;
    }
    final ok =
        (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    final color = ok ? _AnsiColor.green : _AnsiColor.yellow;
    final buffer = StringBuffer()
      ..writeln(
          '${color.code}$_ansiBold← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}$_ansiReset')
      ..writeln('${color.code}  ${_prettyJson(response.data)}$_ansiReset');
    debugPrint(buffer.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer()
      ..writeln(
          '${_AnsiColor.red.code}$_ansiBold✕ ${err.requestOptions.method} ${err.requestOptions.uri}$_ansiReset')
      ..writeln(
          '${_AnsiColor.red.code}  ${err.response != null ? '${err.response!.statusCode} ${_prettyJson(err.response!.data)}' : err.message}$_ansiReset');
    debugPrint(buffer.toString());
    handler.next(err);
  }

  String _prettyJson(dynamic data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
