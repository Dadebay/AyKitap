import 'dart:async';

import 'package:flutter/services.dart';

import '../../modules/book_detail/catalog_book_detail_screen.dart';
import '../navigation/app_navigator.dart';
import '../navigation/root_navigator.dart';

/// Bridges the native `aykitap://book/<id>` deep link hand-off
/// (MainActivity.kt on Android, SceneDelegate.swift on iOS) into a push of
/// [CatalogBookDetailScreen] — reached when the website (or another app)
/// opens that URI to send a user straight to a book.
class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  static const _channel = MethodChannel('com.aykitap.aykitap/deep_link');

  bool _initialized = false;

  /// Call once the app shell (post-splash/onboarding) is mounted, so a
  /// cold-start link has a Navigator to open into.
  void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final link = call.arguments as String?;
        if (link != null) _open(link);
      }
    });
    unawaited(
      _channel.invokeMethod<String>('getInitialLink').then((link) {
        if (link != null) _open(link);
      }),
    );
  }

  void _open(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.host != 'book') return;
    final idSegment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    final bookId = int.tryParse(idSegment ?? '');
    if (bookId == null) return;

    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted) return;
    context.push(CatalogBookDetailScreen(bookId: bookId));
  }
}
