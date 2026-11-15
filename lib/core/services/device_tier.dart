import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Decides once at startup whether this is a low-memory phone, and exposes
/// the answer to the rest of the app.
///
/// Low-end = Android with ~2.5 GB of RAM or less (a "2 GB" phone reports
/// roughly 1.7–2.0 GB as `MemTotal`; a "3 GB" one ~2.7 GB), or one Android
/// itself flags as a low-RAM device (Go edition).
///
/// Force it for testing on any phone:
///   flutter run --dart-define=LOW_END=true    (or =false to force off)
abstract final class DeviceTier {
  static const _forced = String.fromEnvironment('LOW_END');
  static const _lowRamKb = 2560 * 1024;

  static bool _lowEnd = false;
  static int? _totalRamMb;

  static bool get isLowEnd => _lowEnd;

  /// Total RAM in MB when it could be read (Android only), else null.
  static int? get totalRamMb => _totalRamMb;

  /// Animation speed-up applied to every Ticker-driven animation (implicit
  /// ones, controllers, page routes). 0.4 = 2.5x faster, i.e. shorter.
  static const _lowEndTimeDilation = 0.4;

  static Future<void> init() async {
    if (_forced == 'true') {
      _lowEnd = true;
    } else if (_forced == 'false') {
      _lowEnd = false;
    } else if (Platform.isAndroid) {
      try {
        _totalRamMb = _readMemTotalMb();
        final ram = _totalRamMb;
        var low = ram != null && ram * 1024 <= _lowRamKb;
        if (!low) {
          low = (await DeviceInfoPlugin().androidInfo).isLowRamDevice;
        }
        _lowEnd = low;
      } catch (_) {
        _lowEnd = false;
      }
    }
    if (_lowEnd) timeDilation = _lowEndTimeDilation;
    if (kDebugMode) {
      debugPrint('📱 DeviceTier — RAM=${_totalRamMb ?? "?"} MB, '
          'lowEnd=$_lowEnd${_forced.isEmpty ? "" : " (forced)"}');
    }
  }

  static int? _readMemTotalMb() {
    final line = File('/proc/meminfo')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('MemTotal:'));
    final kb = int.parse(RegExp(r'\d+').firstMatch(line)!.group(0)!);
    return kb ~/ 1024;
  }
}
