import 'package:flutter/foundation.dart';

import 'book_api_service.dart';
import 'finished_books_sync_service.dart';

/// Pushes how far the user has read into `POST /books/:bookId/progress`
/// (0–100), which is what fills `progress` on `GET /books/all?my_books=true`
/// and therefore what splits Kitaplygym's "Okuduklarym" shelf from
/// "Bitirdiklerim".
///
/// Every reader ([ReaderProvider] for epub, [PdfReaderScreen],
/// [CbzReaderScreen]) already persists progress locally on a 2s debounce;
/// this rides along on that same save so there's no second timer to keep in
/// sync. Best-effort by design — a failed report is dropped rather than
/// surfaced, because the local save is the source of truth for resuming and
/// the next page turn will report again anyway.
class ReadingProgressReporter {
  ReadingProgressReporter._();
  static final instance = ReadingProgressReporter._();

  /// Last percentage sent per book. Rounding to a whole percent is itself
  /// the throttle: in a 300-page book a single page turn usually lands on
  /// the same integer as the last one, so this drops it without a request,
  /// and a book costs at most ~100 reports end to end.
  final Map<int, int> _lastSent = {};

  /// Reports [fraction] (0–1) for [bookId]. Safe to call on every local
  /// save: it de-dupes internally, never throws, and never blocks the
  /// caller's save.
  void report({required int bookId, required double fraction}) {
    if (!fraction.isFinite) return;
    final percent = (fraction.clamp(0.0, 1.0) * 100).round();
    final last = _lastSent[bookId];
    if (percent == last) return;
    // Optimistic: recorded before the await so two saves landing back to
    // back can't both fire the same percentage.
    _lastSent[bookId] = percent;
    _send(bookId, percent, previous: last);
  }

  Future<void> _send(int bookId, int percent, {int? previous}) async {
    try {
      await BookApiService.updateProgress(bookId, progress: percent);
      // Crossing into 100 is what makes the book appear on "Bitirdiklerim",
      // and that tab only re-fetches when this notifies.
      if (percent >= 100 && (previous == null || previous < 100)) {
        FinishedBooksSyncService.instance.notifyChanged();
      }
    } catch (e) {
      // Offline or a server hiccup — roll back so the next save retries this
      // same percentage instead of the throttle swallowing it. Only when the
      // entry is still the one this call wrote: a newer report (or a
      // [forget] on reader close) that landed while this was in flight
      // must not be clobbered by a stale failure.
      if (_lastSent[bookId] == percent) {
        if (previous != null) {
          _lastSent[bookId] = previous;
        } else {
          _lastSent.remove(bookId);
        }
      }
      if (kDebugMode)
        debugPrint('ReadingProgressReporter: $bookId → $percent% failed — $e');
    }
  }

  /// Drops the de-dupe memory for [bookId] — called when a reader closes so
  /// a book reopened later reports its position once on the first save,
  /// re-syncing a server that may have missed the last report.
  void forget(int bookId) => _lastSent.remove(bookId);
}
