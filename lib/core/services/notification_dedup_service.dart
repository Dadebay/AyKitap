/// Guards against the same push being *shown* or *opened* twice.
///
/// The app runs two push providers side by side (see [OneSignalService]), and
/// OneSignal delivers through the very same Firebase project — so a OneSignal
/// campaign arriving while the app is in the foreground reaches both
/// OneSignal's own presenter *and* [FirebaseMessagingService.onMessage]. The
/// structural payload check in [FirebaseMessagingService.oneSignalNotificationId]
/// is what separates the two providers; this is the second line of defence,
/// covering the cases that check can't: a provider redelivering the same
/// message id, or a tap being routed twice during a cold start.
///
/// Deliberately in-memory and short-lived. The point is to collapse duplicates
/// that arrive within moments of each other, not to remember every
/// notification the app has ever seen — a notification legitimately re-sent
/// hours later should still be shown.
class NotificationDedupService {
  NotificationDedupService._();
  static final instance = NotificationDedupService._();

  /// Long enough to cover a provider retry or a cold-start double-route,
  /// short enough that a genuine re-send is never swallowed.
  static const ttl = Duration(minutes: 5);

  /// Bounds the map for a session that receives an unusual number of pushes —
  /// entries past the TTL are dropped on each call anyway, so this only ever
  /// matters for a burst.
  static const _maxEntries = 64;

  final Map<String, DateTime> _seen = <String, DateTime>{};

  /// Returns true the first time [key] is claimed, false for any repeat
  /// within [ttl]. Callers pass a namespaced key (`'os-open:<id>'`,
  /// `'fcm-show:<id>'`) so a notification being *shown* and later *opened*
  /// aren't mistaken for each other.
  ///
  /// [now] is injectable so the TTL can be tested without waiting it out.
  bool claim(String key, {DateTime? now}) {
    final at = now ?? DateTime.now();
    _evictExpired(at);
    if (_seen.containsKey(key)) return false;
    if (_seen.length >= _maxEntries) {
      // Oldest first — the map preserves insertion order, and every entry
      // still present is within the TTL, so the head is the safest to drop.
      _seen.remove(_seen.keys.first);
    }
    _seen[key] = at;
    return true;
  }

  void _evictExpired(DateTime now) {
    _seen.removeWhere((_, at) => now.difference(at) >= ttl);
  }

  /// Test seam — a fresh process starts with an empty registry, and each test
  /// needs the same.
  void reset() => _seen.clear();
}
