import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/own_book.dart';
import '../../core/services/own_books_store.dart';
import '../main_nav/main_nav_screen.dart';
import '../reader/provider/reader_provider.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LibraryStrings.noInternetSnackbar)),
      );
    }
  }

  void _openBook(OwnBook book) {
    if (book.format == OwnBookFormat.pdf) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PdfReaderScreen(filePath: book.filePath, title: book.title)));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => ReaderProvider(),
            child: ReaderScreen(bookPath: book.filePath, bookId: book.id.hashCode, bookTitle: book.title),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final books = _store.books;
            return Column(
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
                          itemBuilder: (context, i) => _OfflineBookCover(book: books[i], onTap: () => _openBook(books[i])),
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
            );
          },
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
            HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: AppColors.grey3, size: 56),
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

/// Same placeholder-spine styling as the "Öz Kitaplarym" tab — there's no
/// real cover art for a locally imported file, just a format badge + title.
class _OfflineBookCover extends StatelessWidget {
  final OwnBook book;
  final VoidCallback onTap;
  const _OfflineBookCover({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPdf = book.format == OwnBookFormat.pdf;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isPdf ? const [Color(0xFF6B3B3B), Color(0xFF2E1919)] : const [Color(0xFF3B4A6B), Color(0xFF191F2E)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
                child: Text(isPdf ? 'PDF' : 'EPUB', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
              Text(
                book.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
