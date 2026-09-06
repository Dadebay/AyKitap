import 'dart:convert';

import 'package:aykitap/core/network/book_endpoints.dart';
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

/// `ReaderBrightnessController` (shared by the EPUB/PDF/CBZ readers) talks to
/// the `screen_brightness` plugin's method channel on every reader
/// open/close. Left unmocked, an `await` on that call inside a `testWidgets`
/// body never resolves — `AutomatedTestWidgetsFlutterBinding`'s `FakeAsync`
/// zone only delivers an unhandled channel's rejection on a later pump, and
/// nothing here pumps again after a `saveAndClose()`/`dispose()` call — so
/// the test hangs until the framework's own timeout kills it, rather than
/// failing fast the way a plain `test()` calling the same code does.
/// Stubbing every method on the channel to a no-op response is what makes
/// `saveAndClose`/`dispose` safe to await from a `testWidgets` test.
void installFakeScreenBrightness() {
  const channel = MethodChannel('github.com/aaassseee/screen_brightness');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    channel,
    (call) async => switch (call.method) {
      'getSystemScreenBrightness' || 'getApplicationScreenBrightness' => 1.0,
      'hasApplicationScreenBrightnessChanged' => false,
      'isAutoReset' => true,
      'isAnimate' => false,
      'canChangeSystemBrightness' => true,
      _ => null,
    },
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
    installFakeScreenBrightness();
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
    final body = jsonEncode(_responseFor(options));
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Map<String, dynamic> _responseFor(RequestOptions options) {
    if (options.path == StreakEndpoints.streakReport) {
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
    if (options.path == BookEndpoints.booksAll) {
      // Keyed by `genre_id` (a string per the map `booksByGenre` picks its
      // key type from) so a multi-genre fan-out test can tell which request
      // answered which leg, and one book id (3) is shared across genres 1
      // and 2 so the same test can prove the merge step deduplicates it
      // rather than counting it twice.
      final genreId = '${options.queryParameters['genre_id']}';
      final booksByGenre = <String, List<int>>{
        '1': [1, 3],
        '2': [2, 3],
      };
      final ids = booksByGenre[genreId] ?? const [1, 2, 3];
      return {
        'data': {
          'items': [
            for (final id in ids) {'id': id, 'name': 'Book $id'}
          ],
        },
      };
    }
    return {'data': <String, dynamic>{}};
  }

  @override
  void close({bool force = false}) {}
}
