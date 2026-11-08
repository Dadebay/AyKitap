import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book_detail.dart';
import '../network/api_exception.dart';
import 'book_file_api_service.dart';
import 'downloaded_files_store.dart';

part 'book_download_service_impl.dart';

/// Pulls a catalogue book's file onto the device and hands back a local
/// path the readers can open — online once, offline forever after.
///
/// Files land in the application *support* directory rather than documents:
/// on iOS that keeps them out of the Files app (which
/// `LSSupportsOpeningDocumentsInPlace` exposes Documents to) and out of
/// iCloud backup, which is the "hidden place on the phone" this flow is
/// supposed to use. On Android both are app-private either way.
///
/// A [ChangeNotifier] rather than a plain service: [CatalogBookDetailScreen]
/// used to track its own progress/[CancelToken] as private State, which
/// died the moment the screen did — leaving mid-download (back button,
/// switching tabs) used to cancel the download outright, and even once that
/// no longer happened, re-opening the same book got a *fresh* screen with
/// no idea a download was already running, so it just showed the plain
/// "Oku" button again as if nothing was in flight. Tracking progress here
/// instead — keyed by [BookDetail.id], watched via `context.watch` — means
/// any screen open for a book (including one (re)created after the
/// download already started) reads the one real, still-running download.
///
/// The actual download implementation
/// ([_ensureDownloaded]/[_download]/[_bookDir]) lives in
/// book_download_service_impl.dart, a `part` of this file, to keep this
/// file under the 200-line limit.
class BookDownloadService extends ChangeNotifier {
  BookDownloadService._();
  static final instance = BookDownloadService._();

  /// A bare Dio with no `baseUrl` and, crucially, **no auth interceptor**:
  /// the presigned media URL carries its own signature, and sending a
  /// bearer token alongside it can make the media host reject the request.
  static final Dio _downloader = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    // A big CBZ over a slow connection can go quiet for a while between
    // chunks; the API client's 15s would kill it mid-download.
    receiveTimeout: const Duration(minutes: 5),
  ));

  // A book downloads at most one file at a time through this flow (the CTA
  // auto-picks the one best format — see BookOpenFlow._pickFile), so
  // bookId alone is a stable key for all three of these.
  final Map<int, Future<String>> _inFlight = {};
  final Map<int, double?> _progress = {};
  final Map<int, CancelToken> _cancelTokens = {};

  /// 0–1 while [bookId] is downloading, null otherwise.
  double? progressOf(int bookId) => _progress[bookId];

  /// Stops [bookId]'s in-flight download, if any — a no-op otherwise.
  /// Every screen watching [progressOf] sees it drop back to null once the
  /// cancellation unwinds.
  void cancel(int bookId) => _cancelTokens[bookId]?.cancel();

  // notifyListeners is @protected — book_download_service_impl.dart's
  // methods live in an extension, not a subclass, so they call this thin
  // wrapper instead of notifyListeners directly.
  void _notify() => notifyListeners();

  /// Returns the on-disk path of [file] for [bookId], downloading it first
  /// if it isn't already there.
  ///
  /// A file that's already on disk short-circuits before any network call,
  /// so a second "Oku" (or any open in airplane mode) never touches the
  /// network. A second call while one's already running for the same
  /// [bookId] shares that same download rather than racing it with a
  /// second one over the same destination path — the scenario a book
  /// detail screen (re)opened mid-download used to hit. Throws
  /// [ApiException] when the link or the download fails.
  Future<String> ensureDownloaded({
    required int bookId,
    required BookFile file,
  }) {
    final existing = _inFlight[bookId];
    if (existing != null) return existing;
    final future = _ensureDownloaded(bookId: bookId, file: file);
    _inFlight[bookId] = future;
    return future;
  }
}
