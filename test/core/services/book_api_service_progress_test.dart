import 'package:aykitap/core/network/book_endpoints.dart';
import 'package:aykitap/core/services/book_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('finished toggle stores 100 percent when enabled', () async {
    final adapter = FakeDioAdapter.install();

    await BookApiService.setFinished(658, finished: true);

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, BookEndpoints.bookProgress(658));
    expect(request.data, {'progress': 100});
  });

  test('finished toggle deletes progress when disabled', () async {
    final adapter = FakeDioAdapter.install();

    await BookApiService.setFinished(658, finished: false);

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, BookEndpoints.bookProgress(658));
  });
}
