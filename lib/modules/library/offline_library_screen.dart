import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/own_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/own_books_store.dart';
import '../../core/utils/stable_hash.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/own_book_spine_cover.dart';
import '../main_nav/main_nav_screen.dart';
import '../reader/provider/reader_provider.dart';
import '../reader/views/cbz_reader_screen.dart';
import '../reader/views/reader_view.dart';
import '../reader/views/pdf_reader_screen.dart';
import '../../core/localization/strings/library_strings.dart';

/// TZ 12.6: shown right after the splash screen instead of the normal app
/// when there's no network — the only content that can actually be opened
/// with no connection is what's already saved on-device (the "Öz Kitaplarym"
/// imports, copied into app-private storage by [OwnBooksStore]), so that's
/// what this screen lists. A "Baglanyşygy barla" button re-checks
/// connectivity and hands off to the normal app once it's back.
class OfflineLibraryScreen extends StatefulWidget {
  const OfflineLibraryScreen({super.key});

  @override
  State<OfflineLibraryScreen> createState() => _OfflineLibraryScreenState();
}

class _OfflineLibraryScreenState extends State<OfflineLibraryScreen> {
  final _store = OwnBooksStore.instance;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _checkConnection() async {
    if (_checking) return;
    setState(() => _checking = true);
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!mounted) return;
    setState(() => _checking = false);
    if (isOnline) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
    } else {
      context.showAppSnackBar(LibraryStrings.noInternetSnackbar);
    }
  }

  void _openBook(OwnBook book) {
    AnalyticsService.instance.logBookOpened(id: book.id, format: book.format.name);
    switch (book.format) {
      case OwnBookFormat.pdf:
        context.push(PdfReaderScreen(filePath: book.filePath, title: book.title, bookId: stableBookKey(book.id)));
      case OwnBookFormat.cbz:
        context.push(CbzReaderScreen(filePath: book.filePath, title: book.title, bookId: stableBookKey(book.id)));
      case OwnBookFormat.epub:
        context.push(
          ChangeNotifierProvider(
            create: (_) => ReaderProvider(),
            child: ReaderScreen(bookPath: book.filePath, bookId: stableBookKey(book.id), bookTitle: book.title),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<OwnBooksStore>().books;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.grey3.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedWifiDisconnected01, color: AppColors.grey2, size: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(LibraryStrings.noInternetTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(LibraryStrings.noInternetSubtitle, style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: books.isEmpty
                      ? _buildEmpty()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: books.length,
                          itemBuilder: (context, i) => OwnBookSpineCover(
                            book: books[i],
                            onTap: () => _openBook(books[i]),
                            borderRadius: 8,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            wrapAspectRatio: false,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      onPressed: _checking ? null : _checkConnection,
                      child: _checking
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(LibraryStrings.checkConnection, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset('assets/animations/no_internet_connection.json', repeat: true, fit: BoxFit.contain),
            ),
            const SizedBox(height: 14),
            Text(LibraryStrings.noOfflineBooksTitle, style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              LibraryStrings.noOfflineBooksBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
