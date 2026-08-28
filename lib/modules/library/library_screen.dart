import 'package:flutter/material.dart';
import '../../core/localization/strings/library_strings.dart';
import '../../core/services/book_list_api_service.dart';
import '../../core/services/favorites_sync_service.dart';
import '../../core/services/finished_books_sync_service.dart';
import '../../core/services/reading_books_store.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/api_books_tab.dart';
import 'widgets/downloaded_tab.dart';
import 'widgets/own_books_tab.dart';
import 'widgets/shelf_delete.dart';

/// Kitaplagrym Sahypasy — TZ section 7. 6 tabs on a "shelf" style page.
class LibraryScreen extends StatefulWidget {
  /// The shelf to show on first entry. The offline shortcut starts on the
  /// local Downloaded shelf, while normal navigation keeps the reading shelf.
  final int initialTabIndex;

  const LibraryScreen({super.key, this.initialTabIndex = 0})
      : assert(initialTabIndex >= 0 && initialTabIndex < 6);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
      length: 6, vsync: this, initialIndex: widget.initialTabIndex);

  static List<String> get _tabs => [
        LibraryStrings.tabReading,
        LibraryStrings.tabFinished,
        LibraryStrings.tabDownloaded,
        LibraryStrings.tabPurchased,
        LibraryStrings.tabFavorites,
        LibraryStrings.tabOwnBooks,
      ];

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
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(LibraryStrings.libraryTitle,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.grey2,
              labelStyle:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
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
                    fetcher: () async =>
                        (await BookListApiService.listBooks(myBooks: true))
                            .where((b) => !b.isFinished)
                            .toList(),
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
                    cacheLoadedBooks:
                        ReadingBooksStore.instance.mergeFromBackend,
                    openLocalWhenOffline: true,
                    removal: ShelfRemoval.reading,
                  ),
                  ApiBooksTab(
                    fetcher: () => BookListApiService.listBooks(
                      myBooks: true,
                      finished: true,
                    ),
                    emptyLabel: LibraryStrings.emptyFinished,
                    heroShelf: 'finished',
                    showProgress: true,
                    refreshOn: FinishedBooksSyncService.instance,
                    removal: ShelfRemoval.finished,
                  ),
                  // No `/books/all` filter for this — see
                  // DownloadedBooksStore's doc comment.
                  const DownloadedTab(),
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
