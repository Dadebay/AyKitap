import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../../core/models/own_book.dart';
import '../../core/services/own_books_store.dart';
import '../../core/services/purchased_books_store.dart';
import '../book_detail/book_detail_screen.dart';
import '../reader/provider/reader_provider.dart';
import '../reader/views/reader_view.dart';
import '../reader/views/pdf_reader_screen.dart';
import '../../core/localization/strings/library_strings.dart';

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
                  _ReadingTab(books: MockData.generateBooks(6, seed: 12)),
                  _DownloadedTab(books: MockData.generateBooks(4, seed: 20)),
                  const _PurchasedTab(),
                  _SimpleBookListTab(books: MockData.generateBooks(3, seed: 44), emptyLabel: LibraryStrings.emptyFavorites, heart: true),
                  const _OwnBooksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  final String? sub;
  const _EmptyState({required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedLibrary, color: AppColors.grey3, size: 56),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: AppColors.grey2, fontSize: 15)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey3, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _ReadingTab extends StatelessWidget {
  final List<Book> books;
  const _ReadingTab({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return _EmptyState(label: LibraryStrings.emptyReading);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => _ShelfBookCover(book: books[i], progress: ((i + 1) * 17) % 100 / 100),
      ),
    );
  }
}

class _DownloadedTab extends StatelessWidget {
  final List<Book> books;
  const _DownloadedTab({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return _EmptyState(label: LibraryStrings.emptyDownloaded, sub: LibraryStrings.emptyDownloadedSub);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => _ShelfBookCover(book: books[i], downloaded: true),
      ),
    );
  }
}

/// "Satyn Alinanlar" — real per-book purchases from [PurchasedBooksStore],
/// unlike the other tabs here which still show mock catalogue slices.
class _PurchasedTab extends StatefulWidget {
  const _PurchasedTab();

  @override
  State<_PurchasedTab> createState() => _PurchasedTabState();
}

class _PurchasedTabState extends State<_PurchasedTab> {
  @override
  void initState() {
    super.initState();
    PurchasedBooksStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PurchasedBooksStore.instance,
      builder: (context, _) => _SimpleBookListTab(
        books: PurchasedBooksStore.instance.purchasedBooks,
        emptyLabel: LibraryStrings.emptyPurchased,
      ),
    );
  }
}

class _SimpleBookListTab extends StatelessWidget {
  final List<Book> books;
  final String emptyLabel;
  final bool heart;
  const _SimpleBookListTab({required this.books, required this.emptyLabel, this.heart = false});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return _EmptyState(label: emptyLabel);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => _ShelfBookCover(book: books[i], heart: heart),
      ),
    );
  }
}

/// Lays [itemCount] items out across repeating wooden-shelf "compartments"
/// of up to 3 upright covers each, matching the TZ section-7 reference
/// (Surat 5). Shared by the mock catalogue tabs and the own-books tab —
/// [itemBuilder] supplies the cover widget, the shelf just provides slots.
/// Not scrollable itself: the caller wraps it in whatever scroll view fits
/// (a bare scroller for a full-tab grid, or one shared ListView alongside
/// other header content, as in [_OwnBooksTab]).
class _ShelfGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  const _ShelfGrid({required this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    const perShelf = 3;
    final shelfCount = (itemCount / perShelf).ceil();
    return Column(
      children: List.generate(shelfCount, (shelfIndex) {
        final start = shelfIndex * perShelf;
        return _ShelfRow(
          slots: List.generate(3, (i) {
            final idx = start + i;
            return idx < itemCount ? itemBuilder(context, idx) : null;
          }),
        );
      }),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  final List<Widget?> slots;
  const _ShelfRow({required this.slots});

  static const double _imageAspect = 3 / 1.60;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _imageAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/shelf_wood.png', fit: BoxFit.fill),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: slots.map((slot) {
                return Expanded(
                  child: slot == null
                      ? const SizedBox.shrink()
                      : Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: slot),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfBookCover extends StatelessWidget {
  final Book book;
  final bool heart;
  final bool downloaded;
  final double? progress;
  const _ShelfBookCover({required this.book, this.heart = false, this.downloaded = false, this.progress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: book))),
      child: AspectRatio(
        aspectRatio: 0.62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(book.coverImage, fit: BoxFit.cover),
              ),
            ),
            if (heart)
              const Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(child: HugeIcon(icon: HugeIcons.strokeRoundedFavourite, color: Colors.redAccent, size: 12)),
              ),
            if (downloaded)
              Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(child: HugeIcon(icon: HugeIcons.strokeRoundedDownload01, color: AppColors.primary, size: 12)),
              ),
            if (progress != null)
              Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(
                  child: Text(
                    '${(progress! * 100).round()}%',
                    style: const TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// White, shadowed circular badge pinned to a shelf cover's corner — used
/// for the favourite heart, the downloaded checkmark, and the reading %.
class _CornerBadge extends StatelessWidget {
  final Widget child;
  const _CornerBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: child,
    );
  }
}

class _OwnBooksTab extends StatefulWidget {
  const _OwnBooksTab();

  @override
  State<_OwnBooksTab> createState() => _OwnBooksTabState();
}

class _OwnBooksTabState extends State<_OwnBooksTab> {
  final _store = OwnBooksStore.instance;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _pickFile() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub', 'pdf']);
      final picked = result?.files.single;
      final path = picked?.path;
      if (picked == null || path == null) return;
      await _store.addFromPickedFile(sourcePath: path, fileName: picked.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LibraryStrings.fileAddError(e))));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
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
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final books = _store.books;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          children: [
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    if (_picking)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                      )
                    else
                      HugeIcon(icon: HugeIcons.strokeRoundedFolderAdd, color: AppColors.primary, size: 34),
                    const SizedBox(height: 10),
                    Text(LibraryStrings.addFileTitle, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(LibraryStrings.addFileSubtitle, style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (books.isNotEmpty) ...[
              Text(LibraryStrings.addedBooks, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _ShelfGrid(
                itemCount: books.length,
                itemBuilder: (context, i) => _OwnShelfBookCover(book: books[i], onTap: () => _openBook(books[i])),
              ),
              const SizedBox(height: 16),
            ],
            Text(LibraryStrings.localOnlyNotice, style: TextStyle(color: AppColors.grey3, fontSize: 12.5)),
          ],
        );
      },
    );
  }
}

/// Placeholder "spine" cover for a user-imported file — there's no real
/// artwork for these, just a format badge and the filename-derived title.
class _OwnShelfBookCover extends StatelessWidget {
  final OwnBook book;
  final VoidCallback onTap;
  const _OwnShelfBookCover({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPdf = book.format == OwnBookFormat.pdf;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.62,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
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
      ),
    );
  }
}
