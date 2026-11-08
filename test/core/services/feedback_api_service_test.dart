import 'package:aykitap/core/services/feedback_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sends an empty description when the optional field is blank', () async {
    final adapter = FakeDioAdapter.install();

    await FeedbackApiService.createBookSuggestion(
      name: 'Requested book',
      author: 'Requested author',
      language: 'tr',
    );

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.data, containsPair('description', ''));
  });
}
