import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A backend or network failure translated into a message a screen can show
/// directly, instead of every call site having to pick apart a [DioException].
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  /// The backend wraps errors as `{ statusCode, message, error }` like its
  /// success responses (see [ApiEndpoints]'s callers) — this pulls that
  /// `message` out when present, and falls back to something readable for
  /// the cases that never reach the backend at all (no connection, timeout).
  ///
  /// Only trusted for a deliberate business error (400/401/403/409/422 —
  /// "Balansyňyz ýeterlik däl" and the like, worded for a screen to show
  /// as-is). A 404/5xx's `message` is framework-level text meant for a
  /// developer's log ("Cannot POST /api/v1/users/firebase-login", a stack
  /// summary) — a wrong/missing route or a server crash, not something the
  /// backend ever intended a user to read, so those fall through to the
  /// generic message below same as a request that never reached it at all.
  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final trustsServerMessage =
        statusCode != null && statusCode != 404 && statusCode < 500;
    final data = e.response?.data;
    final serverMessage = trustsServerMessage && data is Map
        ? _extractMessage(data['message'])
        : null;
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return ApiException(serverMessage, statusCode: statusCode);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            'Sorag wagty gutardy. Internet baglanyşygyňyzy barlaň.');
      case DioExceptionType.connectionError:
        return const ApiException(
            'Internete birikip bolmady. Baglanyşygyňyzy barlaň.');
      default:
        // Every path that falls through to this generic message is exactly
        // the case where the screen can't say anything more specific than
        // "Näbelli ýalñyşlyk" — a 404/5xx, a response body that isn't the
        // `{message}` shape, or a Dio-level failure with no response at all.
        // [ApiLogInterceptor] already prints a one-line `✕ METHOD path
        // status` for it, but not *why* — the actual status/body is what a
        // developer needs next, so it's dumped here, at the single choke
        // point every such failure passes through, rather than at each of
        // the many call sites that only ever see the generic message. Debug
        // builds only, and deliberately just this exception's own data —
        // not headers/tokens, matching [ApiLogInterceptor]'s same restraint.
        _debugLogUnhandled(e, statusCode);
        return ApiException('Näbelli ýalñyşlyk ýüze çykdy.',
            statusCode: statusCode);
    }
  }

  static void _debugLogUnhandled(DioException e, int? statusCode) {
    if (!kDebugMode) return;
    final uri = e.requestOptions.uri;
    final detail = failureDetail(e);
    final truncated =
        detail.length > 500 ? '${detail.substring(0, 500)}…' : detail;
    debugPrint(
      '\x1B[31m\x1B[1m✕ API ${e.requestOptions.method} ${uri.path} '
      '${statusCode ?? e.type.name} — $truncated\x1B[0m',
    );
  }

  /// The most specific thing available about *why* a request failed.
  ///
  /// The response body when the server answered at all; otherwise the
  /// underlying exception. That last part is the one that used to be thrown
  /// away: [DioException.message] is routinely null for a transport-level
  /// failure, so logging it alone printed `unknown — null`, which says
  /// nothing about what went wrong or which side to fix.
  ///
  /// The runtime type is included because it is the part that separates
  /// causes needing completely different fixes — a `HandshakeException` (the
  /// platform rejected the TLS connection; iOS is markedly stricter than
  /// Android here, so this is a prime suspect whenever one works and the
  /// other doesn't) versus a `SocketException` (the host never resolved, or
  /// refused the connection) versus anything else.
  @visibleForTesting
  static String failureDetail(DioException e) {
    final data = e.response?.data;
    if (data != null) return data.toString().replaceAll('\n', ' ');
    final error = e.error;
    if (error != null) {
      return '${error.runtimeType}: $error'.replaceAll('\n', ' ');
    }
    return e.message ?? 'no response body and no underlying error';
  }

  /// `message` is a plain string for most errors, but a validation failure
  /// (class-validator, on the Nest backend this app talks to) comes back as
  /// a *list* of one-per-field strings instead — e.g.
  /// `["code must be a number conforming to the specified constraints"]`.
  /// Joining that list is what keeps this from crashing on exactly the kind
  /// of 400 a malformed request body produces.
  static String? _extractMessage(dynamic raw) {
    if (raw is String) return raw;
    if (raw is List) return raw.whereType<String>().join('\n');
    return null;
  }

  @override
  String toString() => message;
}
