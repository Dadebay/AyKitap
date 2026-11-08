import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/library_book.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/downloaded_files_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/catalog_book_opener.dart';
import 'continue_reading_card.dart';
import 'reader_empty_state.dart';

/// Resolves the local last-read record to an openable file and pushes the
/// matching reader straight in — same access/format resolution the "Continue
/// reading" card used to gate behind an extra tap. Returns false (nothing
/// pushed) when there's no last book, the file is gone, or access has
/// lapsed, so the caller can fall back to an empty state.
Future<bool> openLastReadBook(BuildContext context) async {
  await LastReadBookStore.instance.load();
  final last = LastReadBookStore.instance.book;
  if (last == null) return false;
  await DownloadedFilesStore.instance.load();
  await BookAccessService.instance.load();
  if (!BookAccessService.instance.canRead(last.bookId)) return false;
  final file = DownloadedFilesStore.instance.best(last.bookId);
  if (file == null || !context.mounted) return false;
  await LastReadBookStore.instance.recordOpened(
    book: LibraryBook(
      id: last.bookId,
      name: last.title,
      image: last.image,
      pageCount: last.pageCount,
    ),
    path: file.path,
    format: file.format,
  );
  if (!context.mounted) return false;
  openCatalogBookFile(
    context,
    path: file.path,
    format: file.format,
    bookId: last.bookId,
    title: last.title,
    pageCount: last.pageCount,
  );
  return true;
}

/// "Continue reading" quick-access tab. It only surfaces the local last-read
/// record while the book file still exists and the account can still read it.
/// A subscription-only book therefore vanishes once that subscription ends;
/// a separately purchased one remains available offline. Kept as a fallback
/// for when the wheel nav's reader tap finds no book to resume — the wheel
/// opens the reader directly in that case, so this screen's own card only
/// ever appears here, as the empty/loading state.
class ReaderTabScreen extends StatefulWidget {
  const ReaderTabScreen({super.key});

  @override
  State<ReaderTabScreen> createState() => _ReaderTabScreenState();
}

class _ReaderTabScreenState extends State<ReaderTabScreen> {
  bool _ready = false;
  Timer? _subscriptionExpiryTimer;
  DateTime? _scheduledExpiry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      LastReadBookStore.instance.load(),
      DownloadedFilesStore.instance.load(),
      BookAccessService.instance.load(),
      SubscriptionService.instance.load(),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  void _scheduleSubscriptionExpiryCheck(DateTime? expiresAt) {
    if (_scheduledExpiry == expiresAt) return;
    _subscriptionExpiryTimer?.cancel();
    _scheduledExpiry = expiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    _subscriptionExpiryTimer = Timer(remaining, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscriptionExpiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _openLastBook(LastReadBook last) => openLastReadBook(context);

  @override
  Widget build(BuildContext context) {
    final last = context.watch<LastReadBookStore>().book;
    final files = context.watch<DownloadedFilesStore>();
    final access = context.watch<BookAccessService>();
    // Rebuild immediately after an account refresh, and evaluate subscription
    // expiry from its current end time on every build.
    final subscription = context.watch<SubscriptionService>();
    _scheduleSubscriptionExpiryCheck(subscription.expiresAt);
    final readable = last != null &&
        files.best(last.bookId) != null &&
        access.canRead(last.bookId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: !_ready
            ? const Center(child: CircularProgressIndicator())
            : readable
                ? ContinueReadingCard(
                    book: last,
                    onTap: () => _openLastBook(last),
                  )
                : const ReaderEmptyState(),
      ),
    );
  }
}
