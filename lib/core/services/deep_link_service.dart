import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../modules/book_detail/catalog_book_detail_screen.dart';
import '../../modules/reader/views/reader_tab_screen.dart';
import '../../modules/streak/streak_screen.dart';
import '../navigation/app_navigator.dart';
import '../navigation/root_navigator.dart';
import 'last_read_book_store.dart';

/// The host used for "reopen whatever this device was last reading".
///
/// A campaign that wants to nudge a reader back into their book sends this
/// instead of a book id, which is the whole point: OneSignal never has to be
/// told what the reader is reading. The book is resolved on-device from
/// [LastReadBookStore] at tap time.
const kLastReadDeepLinkHost = 'reader-last';

/// Maps a push campaign's `additionalData` onto the app's own `aykitap://`
/// URI space.
///
/// Pure and separate from [DeepLinkService] so the mapping can be tested
/// without a Navigator. `bookId` is accepted as either an int or a string:
/// FCM flattens every data value to a string in transit, so a campaign
/// authored with a number still arrives as one.
Uri? deepLinkUriFromNotificationData(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is! String || route.isEmpty) return null;
  final bookId = _asBookId(data['bookId']);
  return switch (route) {
    'book' when bookId != null => Uri.parse('aykitap://book/$bookId'),
    'reader' when bookId != null => Uri.parse('aykitap://reader/$bookId'),
    'reader_last' => Uri.parse('aykitap://$kLastReadDeepLinkHost'),
    'streak' => Uri.parse('aykitap://streak'),
    _ => null,
  };
}

int? _asBookId(Object? raw) {
  if (raw is int) return raw > 0 ? raw : null;
  if (raw is String) {
    final parsed = int.tryParse(raw.trim());
    return (parsed != null && parsed > 0) ? parsed : null;
  }
  return null;
}

/// Bridges every "open the app at X" signal into a screen: the native
/// `aykitap://book/<id>` hand-off (MainActivity.kt on Android,
/// SceneDelegate.swift on iOS) and, via [handleNotificationData], a tapped
/// OneSignal campaign.
class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  static const _channel = MethodChannel('com.aykitap.aykitap/deep_link');

  bool _initialized = false;

  /// A link that arrived before there was anywhere to open it — a push tapped
  /// from a terminated app routes through here well before the app shell
  /// mounts. Held (latest wins) and opened exactly once by [init].
  Uri? _pending;

  /// Test seam standing in for the screen-pushing half of [_open].
  ///
  /// The pending/cold-start sequencing is the part worth testing, and the
  /// real screens can't be built to test it: they fetch from the network the
  /// moment they mount. This replaces only the push, leaving the "is there a
  /// Navigator yet" decision — the thing under test — on the real path.
  @visibleForTesting
  Future<void> Function(Uri uri)? openOverride;

  @visibleForTesting
  void resetForTest() {
    _initialized = false;
    _pending = null;
    openOverride = null;
  }

  @visibleForTesting
  Uri? get pendingLink => _pending;

  /// Call once the app shell (post-splash/onboarding) is mounted, so a
  /// cold-start link has a Navigator to open into.
  void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final link = call.arguments as String?;
        if (link != null) await handleLink(link);
      }
    });
    unawaited(_channel.invokeMethod<String>('getInitialLink').then<void>(
      (link) async {
        if (link != null) await handleLink(link);
      },
    ));
    unawaited(_flushPending());
  }

  /// Opens [link] now, or holds it until the app shell is up.
  Future<void> handleLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri != null) await handleUri(uri);
  }

  Future<void> handleUri(Uri uri) async {
    if (_navigatorContext == null) {
      _pending = uri;
      return;
    }
    await _open(uri);
  }

  /// Entry point for a tapped push campaign. Unknown or incomplete data is
  /// dropped silently — a malformed campaign should do nothing, not crash the
  /// app it just reopened.
  Future<void> handleNotificationData(Map<String, dynamic> data) async {
    final uri = deepLinkUriFromNotificationData(data);
    if (uri != null) await handleUri(uri);
  }

  Future<void> _flushPending() async {
    final pending = _pending;
    if (pending == null) return;
    // Cleared before the await, not after: [_open] yields, and a second
    // flush landing in that window would otherwise open the same link twice.
    _pending = null;
    await _open(pending);
  }

  BuildContext? get _navigatorContext {
    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted) return null;
    return context;
  }

  Future<void> _open(Uri uri) async {
    final context = _navigatorContext;
    if (context == null) {
      _pending = uri;
      return;
    }
    final override = openOverride;
    if (override != null) {
      await override(uri);
      return;
    }
    if (uri.host == 'streak') {
      context.push(const StreakScreen());
      return;
    }
    if (uri.host == kLastReadDeepLinkHost) {
      await _openLastRead(context);
      return;
    }
    if (uri.host != 'book' && uri.host != 'reader') return;
    final idSegment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    final bookId = int.tryParse(idSegment ?? '');
    if (bookId == null) return;

    if (uri.host == 'reader') {
      await LastReadBookStore.instance.load();
      final isCurrentBook = LastReadBookStore.instance.book?.bookId == bookId;
      if (isCurrentBook && context.mounted) {
        final opened = await openLastReadBook(context);
        if (opened) return;
      }
      if (!context.mounted) return;
    }
    context.pushFade(CatalogBookDetailScreen(bookId: bookId));
  }

  /// The book isn't necessarily openable — it may never have been downloaded
  /// on this device, or access may have lapsed with a subscription. Falling
  /// back to the detail screen keeps a "continue reading" nudge useful
  /// instead of doing nothing (or worse, crashing).
  Future<void> _openLastRead(BuildContext context) async {
    await LastReadBookStore.instance.load();
    final last = LastReadBookStore.instance.book;
    if (last == null || !context.mounted) return;
    final opened = await openLastReadBook(context);
    if (opened || !context.mounted) return;
    context.pushFade(CatalogBookDetailScreen(bookId: last.bookId));
  }
}
