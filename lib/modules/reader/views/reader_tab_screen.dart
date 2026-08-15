import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/downloaded_files_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../book_detail/book_open_flow.dart';

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
                ? _ContinueReadingCard(
                    book: last,
                    onTap: () => _openLastBook(last),
                  )
                : const _ReaderEmptyState(),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.book, required this.onTap});

  final LastReadBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final page = book.page + 1;
    final pageLabel = book.pageCount == null
        ? ReaderStrings.resumeAtPage(page)
        : ReaderStrings.resumeAtPageOf(page, book.pageCount!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReaderStrings.continueReading,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 76,
                      height: 112,
                      child: book.image == null || book.image!.isEmpty
                          ? _coverPlaceholder()
                          : NetworkCoverImage(
                              url: ApiConfig.resolveImageUrl(book.image!),
                              placeholder: (_) => _coverPlaceholder(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pageLabel,
                          style: TextStyle(
                            color: AppColors.grey2,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedPlay,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ReaderStrings.continueReading,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        color: AppColors.surface,
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedBook02,
            color: AppColors.grey2,
            size: 28,
          ),
        ),
      );
}

class _ReaderEmptyState extends StatelessWidget {
  const _ReaderEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedBook02,
                color: AppColors.grey2,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            ReaderStrings.noBookYetTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            ReaderStrings.noBookYetSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
