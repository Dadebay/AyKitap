import 'package:flutter/material.dart';
import '../../core/localization/strings/library_strings.dart';
import '../../core/models/library_book.dart';
import '../../core/services/book_list_api_service.dart';
import '../../core/services/favorites_sync_service.dart';
import '../../core/services/finished_books_sync_service.dart';
import '../../core/services/reading_books_store.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/api_books_tab.dart';
import 'widgets/own_books_tab.dart';
import 'widgets/shelf_delete.dart';

/// Kitaplagrym Sahypasy — TZ section 7. Five tabs on a "shelf" style page.
class LibraryScreen extends StatefulWidget {
  static const tabCount = 5;

  static const readingOpensLocalFilesWhenOffline = true;

  static List<String> get tabLabels => [
        LibraryStrings.tabReading,
        LibraryStrings.tabFinished,
        LibraryStrings.tabPurchased,
        LibraryStrings.tabFavorites,
        LibraryStrings.tabOwnBooks,
      ];

  /// The shelf to show on first entry. Reading is also the offline catalogue
  /// shelf now, so both normal and offline navigation start at index zero.
  final int initialTabIndex;

  const LibraryScreen({super.key, this.initialTabIndex = 0})
      : assert(initialTabIndex >= 0 && initialTabIndex < tabCount);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
      length: LibraryScreen.tabCount,
      vsync: this,
      initialIndex: widget.initialTabIndex);

  Future<List<LibraryBook>> _loadReadingBooks() async {
    // The API owns synced progress, while ReadingBooksStore owns the gap
    // between opening the reader and its first debounced progress report.
    // Reconcile the complete response before filtering so a 100% backend row
    // can also evict a stale local reading entry.
    final backendBooks = await BookListApiService.listBooks(myBooks: true);
    await ReadingBooksStore.instance.mergeFromBackend(backendBooks);
    return ReadingBooksStore.instance.books;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(LibraryStrings.libraryTitle, style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.grey2,
              labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              tabAlignment: TabAlignment.start,
              tabs: LibraryScreen.tabLabels.map((t) => Tab(text: t)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // "Started but not done" — `my_books=true` returns every
                  // book the user has opened, finished ones included, and
                  // those belong on the next tab instead. Filtered here
                  // rather than server-side because there's no
                  // `finished=false` filter, only `finished=true`.
                  ApiBooksTab(
                    fetcher: _loadReadingBooks,
                    emptyLabel: LibraryStrings.emptyReading,
                    heroShelf: 'reading',
                    showProgress: true,
                    // Finishing a book moves it off this shelf onto
                    // "Bitirdiklerim", so both tabs watch the same signal.
                    refreshOn: FinishedBooksSyncService.instance,
                    offlineFetcher: () async {
                      await ReadingBooksStore.instance.load();
                      return ReadingBooksStore.instance.books;
                    },
                    // The main tabs stay mounted off-screen. Listen to the
                    // local store so opening a reader updates this shelf
                    // immediately instead of waiting for an app restart.
                    offlineRefreshOn: ReadingBooksStore.instance,
                    openLocalWhenOffline:
                        LibraryScreen.readingOpensLocalFilesWhenOffline,
                    sortByLastOpened: true,
                    removal: ShelfRemoval.reading,
                  ),
                  ApiBooksTab(
                    fetcher: () => BookListApiService.listBooks(
                      myBooks: true,
                      finished: true,
                    ),
                    emptyLabel: LibraryStrings.emptyFinished,
                    heroShelf: 'finished',
                    // Completion is already communicated by this shelf;
                    // intentionally don't enable the 100% corner badge.
                    refreshOn: FinishedBooksSyncService.instance,
                    sortByLastOpened: true,
                    removal: ShelfRemoval.finished,
                  ),
                  ApiBooksTab(
                    fetcher: () => BookListApiService.listBooks(bought: true),
                    emptyLabel: LibraryStrings.emptyPurchased,
                    heroShelf: 'purchased',
                    allowRemovingPurchasedBooks: true,
                    syncsPurchasedAccess: true,
                    removal: ShelfRemoval.purchased,
                  ),
                  ApiBooksTab(
                    fetcher: () => BookListApiService.listBooks(wantsTo: true),
                    emptyLabel: LibraryStrings.emptyFavorites,
                    heroShelf: 'favorites',
                    refreshOn: FavoritesSyncService.instance,
                    removal: ShelfRemoval.favorite,
                  ),
                  const OwnBooksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
