import 'dart:convert';
import 'dart:typed_data';

import 'package:aykitap/core/network/dio_client.dart';
import 'package:aykitap/core/services/account_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

/// Answers `GET /users/me` with a configurable username, and counts how many
/// requests it actually saw — the dedup test's proof that a concurrent
/// [AccountService.refresh] call doesn't fire a second network request.
class _UsersMeAdapter implements HttpClientAdapter {
  _UsersMeAdapter(this.username);

  String username;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    final body = jsonEncode({
      'data': {
        'id': 1,
        'phone': '+99361234567',
        'username': username,
        'balance': 0
      },
    });
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    installFakeSecureStorage();
    AccountService.instance.clear();
  });

  test(
      'a concurrent refresh() shares the in-flight call instead of racing it with stale data',
      () async {
    // This is the exact shape of the bug behind "editing the profile name
    // reverts itself": the old `if (_loading) return;` short-circuit handed
    // a second caller a Future that resolved on its own, independent of
    // whether real data had actually arrived yet — so a caller like
    // ProfileScreen's post-edit sync could read `.user` back before the
    // in-flight fetch (started by something unrelated, e.g. a streak-reward
    // refresh) had populated it with anything, stale or otherwise.
    final adapter = _UsersMeAdapter('Tester');
    DioClient.instance.httpClientAdapter = adapter;

    final first = AccountService.instance.refresh();
    final second = AccountService.instance.refresh();

    // The whole fix in one assertion: both callers hold the *same* Future,
    // not two independent ones that happen to both resolve quickly.
    expect(identical(first, second), isTrue);

    // Awaited (not left dangling) so this fetch is fully settled before the
    // next test's `setUp` swaps the adapter out from under it.
    await Future.wait([first, second]);
  });

  test('the shared call actually completes with real data, not a stale null',
      () async {
    final adapter = _UsersMeAdapter('Menem Biri');
    DioClient.instance.httpClientAdapter = adapter;

    final first = AccountService.instance.refresh();
    final second = AccountService.instance.refresh();
    await Future.wait([first, second]);

    expect(AccountService.instance.user?.username, 'Menem Biri');
    // One shared call, not two independent requests for the same data.
    expect(adapter.requestCount, 1);
  });

  test('refresh() after the in-flight call finishes starts a fresh request',
      () async {
    final adapter = _UsersMeAdapter('First');
    DioClient.instance.httpClientAdapter = adapter;

    await AccountService.instance.refresh();
    expect(adapter.requestCount, 1);

    adapter.username = 'Second';
    await AccountService.instance.refresh();

    expect(adapter.requestCount, 2);
    expect(AccountService.instance.user?.username, 'Second');
  });
}
