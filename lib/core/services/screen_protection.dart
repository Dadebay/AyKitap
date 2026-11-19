import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/root_navigator.dart';
import '../widgets/screenshot_blocked_dialog.dart';
import 'book_api_service.dart';

/// Which catalogue books are subscription-only, remembered on the device.
///
/// Readers can be opened from several places that never load the book's
/// detail (a downloaded shelf, "continue reading", offline), so the flag is
/// recorded whenever it is seen and read back by id. "Unknown" (never seen)
/// is kept apart from "no" so the reader can ask the server once.
class SubscriptionOnlyBooks {
  SubscriptionOnlyBooks._();

  static const _legacyKey = 'subscription_only_book_ids_v1'; // ids = true
  static const _key = 'subscription_flag_books_v2'; // "id:1" / "id:0"
  static Map<int, bool>? _flags;

  static Future<Map<int, bool>> _load() async {
    final cached = _flags;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final flags = <int, bool>{};
    for (final id in prefs.getStringList(_legacyKey) ?? const <String>[]) {
      final parsed = int.tryParse(id);
      if (parsed != null) flags[parsed] = true;
    }
    for (final entry in prefs.getStringList(_key) ?? const <String>[]) {
      final parts = entry.split(':');
      final id = parts.length == 2 ? int.tryParse(parts[0]) : null;
      if (id != null) flags[id] = parts[1] == '1';
    }
    return _flags = flags;
  }

  static Future<void> record(int bookId, bool subscriptionOnly) async {
    debugPrint('🔒 SubscriptionOnlyBooks.record($bookId, $subscriptionOnly)');
    final flags = await _load();
    if (flags[bookId] == subscriptionOnly) return;
    flags[bookId] = subscriptionOnly;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, flags.entries.map((e) => '${e.key}:${e.value ? 1 : 0}').toList());
  }

  /// True/false once seen, null if this book was never looked at.
  static Future<bool?> flagOf(int bookId) async => (await _load())[bookId];

  static Future<bool> contains(int bookId) async => (await flagOf(bookId)) == true;
}

/// Blocks screenshots, screen recording and the app-switcher preview while a
/// subscription-only book is open, using the `no_screenshot` package:
/// Android sets `FLAG_SECURE`; iOS renders the window inside a secure layer,
/// so a screenshot or recording comes out black (iOS has no real "forbid").
/// A screenshot attempt additionally shows a short notice.
class ScreenProtection {
  ScreenProtection._();

  /// How many open readers currently want the protection on.
  static int _holders = 0;

  /// Turns protection on if [bookId] is subscription-only. Returns whether
  /// this call took a hold — pass that to [release] when the reader closes.
  ///
  /// [force] skips the stored lookup — for a screen that has just loaded the
  /// book and already knows it is subscription-only.
  static Future<bool> acquireFor(int bookId, {bool force = false}) async {
    bool subscriptionOnly;
    if (force) {
      subscriptionOnly = true;
    } else {
      // Never seen this book (opened from a shelf without its detail page,
      // or downloaded before the flag was tracked): ask the server once.
      // Offline, or an imported file with no catalogue entry, stays "no".
      subscriptionOnly = (await SubscriptionOnlyBooks.flagOf(bookId)) ?? await _lookUp(bookId);
    }
    debugPrint('🔒 ScreenProtection: book $bookId subscriptionOnly='
        '$subscriptionOnly -> ${subscriptionOnly ? 'ON' : 'off (normal book)'}');
    if (!subscriptionOnly) return false;
    _holders++;
    if (_holders == 1) await _set(true);
    return true;
  }

  static final Set<int> _lookedUpThisSession = {};

  static Future<bool> _lookUp(int bookId) async {
    if (!_lookedUpThisSession.add(bookId)) return false;
    try {
      final book = await BookApiService.getBookById(bookId);
      await SubscriptionOnlyBooks.record(book.id, book.isSubscriptionOnly);
      return book.isSubscriptionOnly;
    } catch (_) {
      return false;
    }
  }

  static Future<void> release() async {
    if (_holders <= 0) return;
    _holders--;
    if (_holders == 0) await _set(false);
  }

  static Future<void> _set(bool secure) async {
    final plugin = NoScreenshot.instance;
    try {
      if (secure) {
        final ok = await plugin.screenshotOff();
        debugPrint('🔒 ScreenProtection: screenshotOff() -> $ok');
        // Hide the page in the app switcher too.
        await plugin.screenshotWithBlur();
        plugin.onScreenshotDetected = (_) {
          debugPrint('🔒 ScreenProtection: SCREENSHOT DETECTED by the app '
              '-> showing the app DIALOG');
          _notify();
        };
        plugin.onScreenRecordingStarted = (_) {
          debugPrint('🔒 ScreenProtection: SCREEN RECORDING started '
              '-> showing the app DIALOG');
          _notify();
        };
        plugin.startCallbacks();
        await plugin.startScreenshotListening();
        debugPrint('🔒 ScreenProtection: listening. A screenshot blocked by '
            'the system itself (Android FLAG_SECURE) shows the SYSTEM toast '
            '"can\'t take screenshot" and never reaches the app, so no app '
            'dialog follows it.');
      } else {
        plugin.removeAllCallbacks();
        await plugin.stopScreenshotListening();
        await plugin.overlayOff();
        await plugin.screenshotOn();
      }
    } catch (e) {
      debugPrint('🔒 ScreenProtection ERROR: $e');
    }
  }

  static void _notify() {
    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted) {
      debugPrint('🔒 ScreenProtection: no context to show the dialog');
      return;
    }
    ScreenshotBlockedDialog.show(context);
  }
}
