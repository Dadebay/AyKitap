import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/downloaded_files_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import '../../reader/utils/catalog_book_opener.dart';
import 'library_book_cover.dart';
import 'library_empty_state.dart';
import 'shelf_delete.dart';
import 'shelf_grid.dart';

part 'api_books_tab_actions.dart';

/// A [LibraryScreen] tab backed by `GET /books/all` — [fetcher] is one of
/// [BookListApiService.listBooks]'s `my_books`/`bought`/`wants_to` filters,
/// wired up per tab in [LibraryScreen]. Kept alive across tab switches
/// ([AutomaticKeepAliveClientMixin]) so flipping tabs back and forth doesn't
/// re-fetch every time.
class ApiBooksTab extends StatefulWidget {
  final Future<List<LibraryBook>> Function() fetcher;
  final String emptyLabel;
  final bool showProgress;
  final bool allowRemovingPurchasedBooks;

  /// Set on the "Satyn alnanlar" tab: its fetch *is* the purchased list, so
  /// the same response also refreshes [BookAccessService]'s offline cache
  /// rather than costing a second identical request.
  final bool syncsPurchasedAccess;

  /// Re-fetches whenever this notifies — e.g. the favorites tab passing
  /// [FavoritesSyncService.instance] so a like/unlike toggled from a book
  /// detail page elsewhere shows up here without a manual pull-to-refresh.
  /// This tab otherwise only reloads on that pull or its own retry button
  /// (`AutomaticKeepAliveClientMixin` keeps it alive across tab switches).
  final Listenable? refreshOn;

  /// Local shadow used when the reading shelf's backend request cannot run.
  final Future<List<LibraryBook>> Function()? offlineFetcher;
  final Future<void> Function(List<LibraryBook> books)? cacheLoadedBooks;

  /// A cached reading-shelf book must bypass `GET /books/:id` in airplane
  /// mode and open the downloaded file directly.
  final bool openLocalWhenOffline;

  /// What a long-press on one of this shelf's covers removes. Every shelf
  /// sets it — until it existed, a book could only be taken off the
  /// downloaded shelf, so there was no way to drop a finished book or a
  /// purchase without opening its detail page.
  final ShelfRemoval? removal;

  const ApiBooksTab({
    super.key,
    required this.fetcher,
    required this.emptyLabel,
    this.showProgress = false,
    this.allowRemovingPurchasedBooks = false,
    this.syncsPurchasedAccess = false,
    this.refreshOn,
    this.offlineFetcher,
    this.cacheLoadedBooks,
    this.openLocalWhenOffline = false,
    this.removal,
  });

  @override
  State<ApiBooksTab> createState() => _ApiBooksTabState();
}

class _ApiBooksTabState extends State<ApiBooksTab>
    with AutomaticKeepAliveClientMixin {
  List<LibraryBook>? _books;
  bool _loading = true;
  String? _error;

  /// Set when the fetch came back 401 — a signed-out visitor gets
  /// [LibraryLoginRequiredState] instead of the raw server error text.
  bool _needsLogin = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOfflineShadow();
    _load();
    widget.refreshOn?.addListener(_load);
  }

  @override
  void dispose() {
    widget.refreshOn?.removeListener(_load);
    super.dispose();
  }

  // setState is @protected — the action methods in api_books_tab_actions.dart
  // live in an extension, not a subclass, so they call this thin wrapper
  // instead of setState directly.
  void _setState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_needsLogin) {
      return LibraryLoginRequiredState(onLoggedIn: _load);
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _load,
                  child: Text(LibraryStrings.retry,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }
    final books = _books ?? const [];
    if (books.isEmpty) return LibraryEmptyState(label: widget.emptyLabel);
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        child: ShelfGrid(
          itemCount: books.length,
          // Keyed by book id — without it, removing an item (unfavoriting,
          // removing a purchase) shifts every following cover into the
          // slot the removed one used to hold, and Flutter's default
          // position-based reconciliation can keep that slot's element
          // (and pending gesture/image state) around across the shrink
          // instead of cleanly rebuilding it for the book now there.
          itemBuilder: (context, i) => LibraryBookCover(
            key: ValueKey(books[i].id),
            book: books[i],
            showProgress: widget.showProgress,
            canRemoveFromPurchased: widget.allowRemovingPurchasedBooks,
            onPurchasedBookRemoved: _load,
            onTap:
                widget.openLocalWhenOffline ? () => _openBook(books[i]) : null,
            onLongPress:
                widget.removal == null ? null : () => _confirmDelete(books[i]),
            // Derived rather than a second flag: the heart *is* this
            // shelf's removal, so the two can't drift apart.
            onUnfavorite: widget.removal == ShelfRemoval.favorite
                ? () => _unfavorite(books[i])
                : null,
          ),
        ),
      ),
    );
  }
}
