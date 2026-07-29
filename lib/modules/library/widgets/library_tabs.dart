import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/library_book.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/book_api_service.dart';
import '../../../core/services/downloaded_books_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/library_strings.dart';
import 'library_book_cover.dart';
import 'library_empty_state.dart';
import 'shelf_grid.dart';

/// No backend endpoint tracks this (see [DownloadedBooksStore]'s doc
/// comment) — the list is whatever's been saved to local storage, not a
/// fetch, so this just watches the store instead of loading/erroring like
/// [ApiBooksTab].
class DownloadedTab extends StatefulWidget {
  const DownloadedTab({super.key});

  @override
  State<DownloadedTab> createState() => _DownloadedTabState();
}

class _DownloadedTabState extends State<DownloadedTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    DownloadedBooksStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final books = context.watch<DownloadedBooksStore>().books;
    if (books.isEmpty) {
      return LibraryEmptyState(label: LibraryStrings.emptyDownloaded, sub: LibraryStrings.emptyDownloadedSub);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => LibraryBookCover(book: books[i]),
      ),
    );
  }
}

/// A [LibraryScreen] tab backed by `GET /books/all` — [fetcher] is one of
/// [BookApiService.listBooks]'s `my_books`/`bought`/`wants_to` filters,
/// wired up per tab in [LibraryScreen]. Kept alive across tab switches
/// ([AutomaticKeepAliveClientMixin]) so flipping tabs back and forth doesn't
/// re-fetch every time.
class ApiBooksTab extends StatefulWidget {
  final Future<List<LibraryBook>> Function() fetcher;
  final String emptyLabel;
  final bool showProgress;
  const ApiBooksTab({super.key, required this.fetcher, required this.emptyLabel, this.showProgress = false});

  @override
  State<ApiBooksTab> createState() => _ApiBooksTabState();
}

class _ApiBooksTabState extends State<ApiBooksTab> with AutomaticKeepAliveClientMixin {
  List<LibraryBook>? _books;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await widget.fetcher();
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(LibraryStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
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
          itemBuilder: (context, i) => LibraryBookCover(book: books[i], showProgress: widget.showProgress),
        ),
      ),
    );
  }
}
