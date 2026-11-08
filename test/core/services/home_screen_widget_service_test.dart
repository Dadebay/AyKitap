import 'package:aykitap/core/services/home_screen_widget_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  late List<MethodCall> calls;
  late Map<String, Object?> storage;

  setUp(() {
    calls = [];
    storage = {};
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      final arguments = call.arguments as Map;
      switch (call.method) {
        case 'getWidgetData':
          return storage[arguments['id']] ?? arguments['defaultValue'];
        case 'saveWidgetData':
          storage[arguments['id'] as String] = arguments['data'];
          return true;
        default:
          return true;
      }
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  void expectSafeWrites() {
    final writes = calls.where((call) => call.method == 'saveWidgetData');
    expect(writes, isNotEmpty);
    for (final call in writes) {
      final arguments = call.arguments as Map;
      // Dart null becomes NSNull in the native method-channel dictionary.
      // home_widget 0.9.3 passes it to UserDefaults, which aborts on iOS.
      expect(arguments['data'], isNotNull, reason: '${arguments['id']}');
      expect(arguments['data'], anyOf(isA<String>(), isA<int>()));
    }
  }

  Future<void> syncEmptyBook() => HomeScreenWidgetService.sync(
        bookId: null,
        title: null,
        page: 0,
        pageCount: null,
        streak: 0,
        bestStreak: 0,
        todayPages: 0,
        goalMinutes: 15,
        weekRead: List.filled(7, false),
      );

  test('fresh launch without a last-read book writes only safe native values',
      () async {
    await syncEmptyBook();

    expectSafeWrites();
    expect(calls.first.method, 'setAppGroupId');
    expect(calls.first.arguments,
        {'groupId': HomeScreenWidgetService.iosAppGroupId});
    expect(storage['book_id'], -1);
    expect(storage['book_title'], 'Start your reading journey');
    expect(storage['book_author'], '');
    expect(storage['book_page'], 0);
    expect(storage['book_page_count'], 0);
    expect(storage['book_cover'], '');
    expect(storage['week_read'], '0000000');
    expect(
      calls
          .where((call) => call.method == 'updateWidget')
          .map((call) => (call.arguments as Map)['ios']),
      containsAll(['AykitapLastBookWidget', 'AykitapStreakWidget']),
    );
  });

  test('clearing a previously read book overwrites stale widget state',
      () async {
    storage.addAll({
      'book_id': 478,
      'book_title': 'Previous book',
      'book_author': 'Previous author',
      'book_page': 25,
      'book_page_count': 225,
      'book_cover': '/previous-cover.png',
    });

    await syncEmptyBook();

    expectSafeWrites();
    expect(storage['book_id'], -1);
    expect(storage['book_title'], 'Start your reading journey');
    expect(storage['book_author'], '');
    expect(storage['book_page'], 0);
    expect(storage['book_page_count'], 0);
    expect(storage['book_cover'], '');
  });

  test('book sync preserves metadata and does not clear an unchanged cover',
      () async {
    storage['book_cover'] = '/existing-cover.png';

    await HomeScreenWidgetService.syncBook(
      bookId: 478,
      title: 'The art of spending money',
      author: 'Morgan Housel',
      page: 25,
      pageCount: 225,
    );

    expectSafeWrites();
    expect(storage['book_id'], 478);
    expect(storage['book_title'], 'The art of spending money');
    expect(storage['book_author'], 'Morgan Housel');
    expect(storage['book_page'], 25);
    expect(storage['book_page_count'], 225);
    expect(storage['book_cover'], '/existing-cover.png');
  });

  for (final coverUrl in <String?>[null, '']) {
    test('book sync handles missing metadata and a $coverUrl cover safely',
        () async {
      storage['book_cover'] = '/previous-cover.png';

      await HomeScreenWidgetService.syncBook(
        bookId: 478,
        title: null,
        page: 0,
        pageCount: null,
        coverUrl: coverUrl,
        updateCover: true,
      );

      expectSafeWrites();
      expect(storage['book_id'], 478);
      expect(storage['book_title'], 'Start your reading journey');
      expect(storage['book_author'], '');
      expect(storage['book_page_count'], 0);
      expect(storage['book_cover'], '');
    });
  }
}
