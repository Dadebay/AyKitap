import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/strings/home_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';

enum _ConnectionNotice { hidden, offline, restored }

/// A small, non-blocking network status layer over Home.
///
/// Existing shelves remain readable while offline. When connectivity returns,
/// the success state appears once, asks Home to refresh behind the current
/// content, then gets out of the way automatically.
class HomeConnectionBanner extends StatefulWidget {
  const HomeConnectionBanner({super.key, required this.onReconnected});

  final Future<void> Function() onReconnected;

  @override
  State<HomeConnectionBanner> createState() => _HomeConnectionBannerState();
}

class _HomeConnectionBannerState extends State<HomeConnectionBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _hideTimer;
  _ConnectionNotice _notice = _ConnectionNotice.hidden;
  bool _hasObservedState = false;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(_handle);
    unawaited(Connectivity().checkConnectivity().then(_handle));
  }

  void _handle(List<ConnectivityResult> results) {
    if (!mounted) return;
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (offline) {
      _hideTimer?.cancel();
      _hasObservedState = true;
      _wasOffline = true;
      if (_notice != _ConnectionNotice.offline) {
        setState(() => _notice = _ConnectionNotice.offline);
      }
      return;
    }

    final recovered = _hasObservedState && _wasOffline;
    _hasObservedState = true;
    _wasOffline = false;
    if (!recovered) return;

    setState(() => _notice = _ConnectionNotice.restored);
    unawaited(widget.onReconnected());
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _notice = _ConnectionNotice.hidden);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final visible = _notice != _ConnectionNotice.hidden;
    final restored = _notice == _ConnectionNotice.restored;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSwitcher(
        duration: reduceMotion ? AppMotion.instant : AppMotion.standard,
        switchInCurve: AppMotion.easeOut,
        switchOutCurve: AppMotion.easeOut,
        transitionBuilder: (child, animation) {
          if (reduceMotion) {
            return FadeTransition(opacity: animation, child: child);
          }
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.18),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: visible
            ? Material(
                key: ValueKey(_notice),
                color: restored ? const Color(0xFF216E52) : AppColors.card,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        restored
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: restored ? Colors.white : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          restored
                              ? HomeStrings.connectionRestored
                              : HomeStrings.offlineLibraryReady,
                          style: TextStyle(
                            color: restored ? Colors.white : AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('hidden')),
      ),
    );
  }
}
