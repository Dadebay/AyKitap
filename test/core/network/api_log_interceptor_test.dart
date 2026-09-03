// Regression cover for ApiLogInterceptor's redaction.
//
// It used to pretty-print the request body verbatim — a Firebase idToken,
// an Authorization header, an FCM/APNS token all reached the terminal in
// full whenever they showed up in a request/response.
import 'package:aykitap/core/network/api_log_interceptor.dart';
import 'package:aykitap/core/network/dio_client.dart';
import 'package:aykitap/core/utils/log_redaction.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the [RequestOptions] it actually received (what would go out
/// over the wire) without touching a real network — used to prove the
/// interceptor only redacts what it *prints*, never what it *sends*.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> received = [];
  int statusCode = 200;
  String responseBody = '{"data":{}}';

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    received.add(options);
    return ResponseBody.fromString(responseBody, statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Captures every line [debugPrint] would otherwise send to the console,
/// restoring the original on [dispose] so later tests aren't affected.
class _CapturedLog {
  _CapturedLog() : _original = debugPrint {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) lines.add(message);
    };
  }

  final List<String> lines = [];
  final void Function(String? message, {int? wrapWidth}) _original;

  String get all => lines.join('\n');

  void dispose() => debugPrint = _original;
}

void main() {
  group('API logging gate', () {
    test('logging is disabled unless debug mode and explicit opt-in agree', () {
      expect(
        shouldAttachApiLogInterceptor(
          isDebugMode: true,
          requested: false,
        ),
        isFalse,
      );
      expect(
        shouldAttachApiLogInterceptor(
          isDebugMode: false,
          requested: true,
        ),
        isFalse,
      );
      expect(
        shouldAttachApiLogInterceptor(
          isDebugMode: true,
          requested: true,
        ),
        isTrue,
      );
    });
  });

  group('log_redaction (pure functions)', () {
    test('a nested idToken is masked', () {
      final result = redactedForLog({
        'user': {'idToken': 'abcdefghijklmnopqrstuvwxyz123456'},
      });

      expect(result['user']['idToken'],
          maskSecret('abcdefghijklmnopqrstuvwxyz123456'));
      expect(result['user']['idToken'], isNot(contains('ghijklmnop')));
    });

    test('an Authorization header value is masked', () {
      final result = redactedForLog({
        'Authorization': 'Bearer stripe_test_secret_fixture_123456789',
        'Content-Type': 'application/json',
      });

      expect(result['Authorization'], isNot(contains('stripe_test_secret_fixture_123456789')));
      expect(result['Content-Type'], 'application/json');
    });

    test('a token inside a list of objects is masked', () {
      final result = redactedForLog({
        'sessions': [
          {'device': 'pixel', 'accessToken': 'longlivedaccesstoken123456789'},
          {'device': 'iphone', 'accessToken': 'anotherlongaccesstoken98765'},
        ],
      });

      final sessions = result['sessions'] as List;
      expect((sessions[0] as Map)['accessToken'],
          isNot(contains('longlivedaccesstoken')));
      expect((sessions[1] as Map)['accessToken'],
          isNot(contains('anotherlongaccesstoken')));
      // Non-sensitive fields in the same objects survive untouched.
      expect((sessions[0] as Map)['device'], 'pixel');
      expect((sessions[1] as Map)['device'], 'iphone');
    });

    test('ordinary fields like name/email are never touched', () {
      final result = redactedForLog({
        'name': 'Aýgül',
        'email': 'aygul@example.com',
        'phone': '+99361234567',
      });

      expect(result['name'], 'Aýgül');
      expect(result['email'], 'aygul@example.com');
      expect(result['phone'], '+99361234567');
    });

    test('a very short secret is fully masked, not partially shown', () {
      expect(maskSecret('abc'), '***');
      expect(maskSecret('1234567890'), '***'); // exactly 10 — still short
    });

    test('the original Map is not mutated', () {
      final original = {
        'user': {'idToken': 'abcdefghijklmnopqrstuvwxyz123456'},
      };
      final snapshotBeforeCall = Map<String, dynamic>.from(
          (original['user']! as Map).cast<String, dynamic>());

      redactedForLog(original);

      expect(original['user'], snapshotBeforeCall);
      expect((original['user']! as Map)['idToken'],
          'abcdefghijklmnopqrstuvwxyz123456');
    });

    test('a sensitive key in the URL query is masked', () {
      final redacted = redactedUrlForLog(Uri.parse(
          'https://api.example.com/auth?token=abcdefghijklmnop&lang=tk'));

      expect(redacted, isNot(contains('abcdefghijklmnop')));
      expect(redacted, contains('lang=tk'));
    });
  });

  group('ApiLogInterceptor', () {
    late _CapturedLog log;
    late _RecordingAdapter adapter;
    late Dio dio;

    setUp(() {
      log = _CapturedLog();
      adapter = _RecordingAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = adapter
        ..interceptors.add(const ApiLogInterceptor());
    });

    tearDown(() => log.dispose());

    test('the real request handler still gets the full, unredacted token',
        () async {
      const realToken = 'THIS_IS_THE_REAL_UNMASKED_TOKEN_VALUE';
      await dio.post('/login',
          data: {
            'idToken': realToken,
          },
          options: Options(headers: {
            'Authorization': 'Bearer $realToken',
          }));

      expect(adapter.received, hasLength(1));
      expect(adapter.received.first.data['idToken'], realToken);
      expect(
          adapter.received.first.headers['Authorization'], 'Bearer $realToken');
    });

    test('prints metadata only and leaves bodies and headers out', () async {
      const realToken = 'THIS_IS_THE_REAL_UNMASKED_TOKEN_VALUE';
      adapter.responseBody =
          '{"phone":"+99361234567","email":"private@example.com"}';
      await dio.post('/login',
          data: {
            'idToken': realToken,
          },
          options: Options(headers: {
            'Authorization': 'Bearer $realToken',
          }));

      expect(log.all, isNot(contains(realToken)));
      expect(log.all, isNot(contains('idToken')));
      expect(log.all, isNot(contains('Authorization')));
      expect(log.all, isNot(contains('+99361234567')));
      expect(log.all, isNot(contains('private@example.com')));
      expect(log.all, contains('→ POST /login'));
      expect(log.all, matches(RegExp(r'← 200 POST /login \(\d+ms\)')));
    });

    test('drops host and query values from the printed path', () async {
      await dio.get('/books', queryParameters: {
        'search': 'private title',
        'token': 'query-secret-value',
      });

      expect(log.all, contains('→ GET /books'));
      expect(log.all, isNot(contains('api.example.com')));
      expect(log.all, isNot(contains('private title')));
      expect(log.all, isNot(contains('query-secret-value')));
      expect(log.all, isNot(contains('search=')));
    });

    test('an HTTP error logs status but never its response body', () async {
      adapter
        ..statusCode = 401
        ..responseBody =
            '{"message":"private backend detail","phone":"+99361111111"}';

      await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));

      expect(log.all, matches(RegExp(r'✕ GET /users/me 401 \(\d+ms\)')));
      expect(log.all, isNot(contains('private backend detail')));
      expect(log.all, isNot(contains('+99361111111')));
    });
  });
}
