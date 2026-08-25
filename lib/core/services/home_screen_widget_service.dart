import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

/// Mirrors the compact reading state that the native iOS and Android home
/// screen widgets need. Native widgets cannot read Flutter's preferences
/// directly, so every update is written through HomeWidget's shared store.
class HomeScreenWidgetService {
  HomeScreenWidgetService._();

  static const iosAppGroupId = 'group.com.aykitap.aykitap';
  static const _androidBookProvider = 'AykitapReadingWidgetProvider';
  static const _androidStreakProvider = 'AykitapStreakWidgetProvider';
  static const _iosBookKind = 'AykitapLastBookWidget';
  static const _iosStreakKind = 'AykitapStreakWidget';

  static Future<void> sync({
    required int? bookId,
    required String? title,
    String? author,
    required int page,
    required int? pageCount,
    required int streak,
    required int bestStreak,
    required int todayPages,
    required int goalMinutes,
    required List<bool> weekRead,
    String? coverUrl,
  }) async {
    try {
      await _prepare();
      await Future.wait([
        _saveBookData(
          bookId: bookId,
          title: title,
          author: author,
          page: page,
          pageCount: pageCount,
        ),
        _saveStreakData(
          streak: streak,
          bestStreak: bestStreak,
          todayPages: todayPages,
          goalMinutes: goalMinutes,
          weekRead: weekRead,
        ),
      ]);
      await _updateNativeWidgets();
      await _saveCoverAndRefresh(coverUrl, updateCover: true);
    } catch (error, stackTrace) {
      debugPrint('Home-screen widget sync failed: $error\n$stackTrace');
    }
  }

  static Future<void> syncBook({
    required int? bookId,
    required String? title,
    String? author,
    required int page,
    required int? pageCount,
    String? coverUrl,
    bool updateCover = false,
  }) async {
    try {
      await _prepare();
      await _saveBookData(
        bookId: bookId,
        title: title,
        author: author,
        page: page,
        pageCount: pageCount,
      );
      // Text and progress appear immediately. A remote cover can arrive in a
      // second lightweight refresh without holding the rest of the widget.
      await _updateNativeWidgets();
      await _saveCoverAndRefresh(coverUrl, updateCover: updateCover);
    } catch (error, stackTrace) {
      debugPrint('Home-screen book widget sync failed: $error\n$stackTrace');
    }
  }

  static Future<void> syncStreak({
    required int streak,
    required int bestStreak,
    required int todayPages,
    required int goalMinutes,
    required List<bool> weekRead,
  }) async {
    try {
      await _prepare();
      await _saveStreakData(
        streak: streak,
        bestStreak: bestStreak,
        todayPages: todayPages,
        goalMinutes: goalMinutes,
        weekRead: weekRead,
      );
      await _updateNativeWidgets();
    } catch (error, stackTrace) {
      debugPrint('Home-screen streak widget sync failed: $error\n$stackTrace');
    }
  }

  static Future<void> _prepare() => HomeWidget.setAppGroupId(iosAppGroupId);

  static Future<void> _saveBookData({
    required int? bookId,
    required String? title,
    required String? author,
    required int page,
    required int? pageCount,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<int>('book_id', bookId),
      HomeWidget.saveWidgetData<String>('book_title', title),
      HomeWidget.saveWidgetData<String>('book_author', author),
      HomeWidget.saveWidgetData<int>('book_page', page),
      HomeWidget.saveWidgetData<int>('book_page_count', pageCount),
    ]);
  }

  static Future<void> _saveStreakData({
    required int streak,
    required int bestStreak,
    required int todayPages,
    required int goalMinutes,
    required List<bool> weekRead,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<int>('streak', streak),
      HomeWidget.saveWidgetData<int>('best_streak', bestStreak),
      HomeWidget.saveWidgetData<int>('today_pages', todayPages),
      HomeWidget.saveWidgetData<int>('today_weekday', DateTime.now().weekday),
      HomeWidget.saveWidgetData<int>('goal_minutes', goalMinutes),
      HomeWidget.saveWidgetData<String>(
        'week_read',
        weekRead.map((met) => met ? '1' : '0').join(),
      ),
    ]);
  }

  static Future<void> _saveCoverAndRefresh(
    String? coverUrl, {
    required bool updateCover,
  }) async {
    if (!updateCover) return;
    if (coverUrl == null || coverUrl.isEmpty) {
      await HomeWidget.saveWidgetData<String>('book_cover', null);
      await _updateNativeWidgets();
      return;
    }
    try {
      await HomeWidget.saveImage(
        'book_cover',
        NetworkImage(coverUrl),
        appGroupId: iosAppGroupId,
      );
      await _updateNativeWidgets();
    } catch (error) {
      // A cover failure must never prevent title/page/streak data appearing.
      debugPrint('Home-screen widget cover could not be cached: $error');
    }
  }

  static Future<void> _updateNativeWidgets() async {
    await Future.wait([
      HomeWidget.updateWidget(
        androidName: _androidBookProvider,
        iOSName: _iosBookKind,
        qualifiedAndroidName:
            'com.aykitap.aykitap.AykitapReadingWidgetProvider',
      ),
      HomeWidget.updateWidget(
        androidName: _androidStreakProvider,
        iOSName: _iosStreakKind,
        qualifiedAndroidName: 'com.aykitap.aykitap.AykitapStreakWidgetProvider',
      ),
    ]);
  }
}
