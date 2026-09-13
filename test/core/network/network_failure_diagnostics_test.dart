// A transport-level failure used to reach the developer as "unknown — null"
// and skip the fallback host entirely, which is what made an iOS-only outage
// impossible to tell apart from an Android one that quietly recovered.
import 'dart:io';

import 'package:aykitap/core/network/api_exception.dart';
import 'package:aykitap/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final _options = RequestOptions(path: '/collections/all');

DioException _failure({
  required DioExceptionType type,
  Object? error,
  String? message,
  Response<dynamic>? response,
}) =>
    DioException(
      requestOptions: _options,
      type: type,
      error: error,
      message: message,
      response: response,
    );

void main() {
  group('failureDetail', () {
    test('names the underlying exception when there is no response', () {
      // The iOS case: a TLS connection the platform refused. Dio files it as
      // `unknown` with a null message, so the HandshakeException is the only
      // thing that says what actually happened.
      final detail = ApiException.failureDetail(_failure(
        type: DioExceptionType.unknown,
        error: const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
      ));

      expect(detail, contains('HandshakeException'));
      expect(detail, contains('CERTIFICATE_VERIFY_FAILED'));
    });

    test('distinguishes a host that never resolved', () {
      final detail = ApiException.failureDetail(_failure(
        type: DioExceptionType.connectionError,
        error: const SocketException('Failed host lookup: example.invalid'),
      ));

      expect(detail, contains('SocketException'));
      expect(detail, contains('Failed host lookup'));
    });

    test('prefers the response body when the server did answer', () {
      final detail = ApiException.failureDetail(_failure(
        type: DioExceptionType.badResponse,
        error: const SocketException('ignored'),
        response: Response<dynamic>(
          requestOptions: _options,
          statusCode: 500,
          data: {'message': 'Internal server error'},
        ),
      ));

      expect(detail, contains('Internal server error'));
      expect(detail, isNot(contains('SocketException')));
    });

    test('falls back to the message, then to a plain statement of the gap', () {
      expect(
        ApiException.failureDetail(
            _failure(type: DioExceptionType.unknown, message: 'boom')),
        'boom',
      );
      // What used to print as a bare "null".
      expect(
        ApiException.failureDetail(_failure(type: DioExceptionType.unknown)),
        isNot(contains('null')),
      );
    });

    test('keeps the line single-line so one failure stays one log line', () {
      final detail = ApiException.failureDetail(_failure(
        type: DioExceptionType.unknown,
        error: const SocketException('first line\nsecond line'),
      ));

      expect(detail, isNot(contains('\n')));
    });
  });

  group('shouldRetryOnFallbackHost', () {
    test('retries a TLS refusal, which arrives as `unknown`', () {
      // The regression this guards: keying off connectionError alone meant a
      // platform-refused TLS connection never reached the fallback host.
      expect(
        shouldRetryOnFallbackHost(_failure(
          type: DioExceptionType.unknown,
          error: const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
        )),
        isTrue,
      );
    });

    test('retries a connection error and a connect timeout', () {
      expect(
        shouldRetryOnFallbackHost(
            _failure(type: DioExceptionType.connectionError)),
        isTrue,
      );
      expect(
        shouldRetryOnFallbackHost(
            _failure(type: DioExceptionType.connectionTimeout)),
        isTrue,
      );
    });

    test('does not retry once a server has answered', () {
      // The host is reachable; the problem is the request or the server, and
      // asking a different origin would only hide that.
      expect(
        shouldRetryOnFallbackHost(_failure(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
              requestOptions: _options, statusCode: 404, data: const {}),
        )),
        isFalse,
      );
    });

    test('does not retry a cancelled request or a receive timeout', () {
      expect(
        shouldRetryOnFallbackHost(_failure(type: DioExceptionType.cancel)),
        isFalse,
      );
      // The connection was established — a slow body is not a bad host.
      expect(
        shouldRetryOnFallbackHost(
            _failure(type: DioExceptionType.receiveTimeout)),
        isFalse,
      );
    });
  });
}
