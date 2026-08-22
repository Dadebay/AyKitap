import 'package:dio/dio.dart';

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
  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    final serverMessage = data is Map ? _extractMessage(data['message']) : null;
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return ApiException(serverMessage, statusCode: e.response?.statusCode);
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
        return ApiException('Näbelli ýalñyşlyk ýüze çykdy.',
            statusCode: e.response?.statusCode);
    }
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
