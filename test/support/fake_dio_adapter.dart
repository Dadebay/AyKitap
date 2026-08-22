import 'dart:convert';

import 'package:aykitap/core/network/streak_endpoints.dart';
import 'package:aykitap/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DioClient`'s request interceptor reads the bearer token via
/// `flutter_secure_storage` on *every* call — including ones this fake
/// adapter would otherwise happily answer — and that plugin has no
/// implementation registered in a plain `flutter test` run, so it throws
/// `MissingPluginException` before the request ever reaches
/// [FakeDioAdapter.fetch]. Stubbing the channel to always return "no token"
/// is what makes any DioClient-backed call safe to exercise in a unit test.
void installFakeSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    channel,
    (call) async => null,
  );
}

/// Test double for [DioClient.instance]'s transport.
///
/// [ReaderProvider]/[StreakService]/[ReadingProgressReporter] talk to the
/// backend through the single static `DioClient.instance` — there is no
/// constructor injection seam — so reader-lifecycle tests swap this in via
/// [install] instead of letting those calls hit the real network (slow,
/// non-deterministic, and unavailable in CI).
///
/// Records every request it receives (see [requests]) so a test can assert
/// on what a lifecycle transition actually sent, and returns a canned 200
/// response shaped to match whichever endpoint was called — enough for the
/// app's `on ApiException` handling to see success and move on.
class FakeDioAdapter implements HttpClientAdapter {
  FakeDioAdapter({this.statusCode = 200});

  final int statusCode;
  final List<RequestOptions> requests = [];

  /// Installs this adapter on [dio] (default [DioClient.instance]) and
  /// returns it so the caller can assert on [requests] afterwards.
  static FakeDioAdapter install({Dio? dio, int statusCode = 200}) {
    installFakeSecureStorage();
    final adapter = FakeDioAdapter(statusCode: statusCode);
    (dio ?? DioClient.instance).httpClientAdapter = adapter;
    return adapter;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = jsonEncode(_responseFor(options.path));
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Map<String, dynamic> _responseFor(String path) {
    if (path == StreakEndpoints.streakReport) {
      return {
        'data': {
          'today': {
            'date': '2026-01-01',
            'seconds': 0,
            'minutes': 0,
            'pages': 0,
            'goal_met': false,
          },
          'current_streak': 0,
          'best_streak': 0,
          'rewards': <Object?>[],
        },
      };
    }
    return {'data': <String, dynamic>{}};
  }

  @override
  void close({bool force = false}) {}
}
