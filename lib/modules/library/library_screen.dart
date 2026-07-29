import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/book_api_service.dart';
import '../../core/localization/strings/library_strings.dart';
import 'widgets/library_tabs.dart';
import 'widgets/own_books_tab.dart';

/// Kitaplagrym Sahypasy — TZ section 7. 5 tabs on a "shelf" style page.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 5, vsync: this);

  static List<String> get _tabs => [
        LibraryStrings.tabReading,
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
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ApiBooksTab(
                    fetcher: () => BookApiService.listBooks(myBooks: true),
                    emptyLabel: LibraryStrings.emptyReading,
                    showProgress: true,
                  ),
                  // No `/books/all` filter for this — see
                  // DownloadedBooksStore's doc comment.
                  const DownloadedTab(),
                  ApiBooksTab(
                    fetcher: () => BookApiService.listBooks(bought: true),
                    emptyLabel: LibraryStrings.emptyPurchased,
                  ),
                  ApiBooksTab(
                    fetcher: () => BookApiService.listBooks(wantsTo: true),
                    emptyLabel: LibraryStrings.emptyFavorites,
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
