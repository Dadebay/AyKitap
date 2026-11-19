import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Routes hardware volume presses to the reader that currently owns the
/// screen. The native side leaves volume keys alone outside a reader.
class ReaderVolumeKeys {
  ReaderVolumeKeys._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onVolumeKey') return;
      if (call.arguments == 'next') {
        _next?.call();
      } else if (call.arguments == 'previous') {
        _previous?.call();
      } else if (call.arguments == 'nextChapter') {
        _nextChapter?.call();
      } else if (call.arguments == 'previousChapter') {
        _previousChapter?.call();
      }
    });
  }

  static final instance = ReaderVolumeKeys._();
  static const _channel = MethodChannel('com.aykitap.aykitap/reader_volume');

  Object? _owner;
  VoidCallback? _next;
  VoidCallback? _previous;
  VoidCallback? _nextChapter;
  VoidCallback? _previousChapter;

  void activate(Object owner,
      {required VoidCallback next,
      required VoidCallback previous,
      VoidCallback? nextChapter,
      VoidCallback? previousChapter}) {
    _owner = owner;
    _next = next;
    _previous = previous;
    _nextChapter = nextChapter;
    _previousChapter = previousChapter;
    if (Platform.isAndroid) unawaited(_setNativeActive(true));
  }

  void deactivate(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _next = null;
    _previous = null;
    _nextChapter = null;
    _previousChapter = null;
    if (Platform.isAndroid) unawaited(_setNativeActive(false));
  }

  Future<void> _setNativeActive(bool active) async {
    try {
      await _channel.invokeMethod<void>('setReaderActive', {
        'active': active,
        'chapters': active && _nextChapter != null,
      });
    } on MissingPluginException {
      // Old native builds and widget tests have no volume-key bridge.
    } on PlatformException {
      // A reader should still open if the bridge is unavailable.
    }
  }
}
