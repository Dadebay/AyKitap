part of 'catalog_book_detail_screen.dart';

/// The CTA row's read/buy/cancel actions, the finished/favorite toggles,
/// share, and navigating to an author or genre — everything this screen
/// does in response to a tap, as opposed to the initial data load (see the
/// main file) or the widget tree itself (catalog_book_detail_body.dart).
extension _CatalogBookDetailActions on _CatalogBookDetailScreenState {
  Future<void> _onRead() async {
    final book = _book;
    if (book == null) return;
    await _flow(book).read();
    await _resolveAccess();
  }

  Future<void> _onBuy() async {
    final book = _book;
    if (book == null) return;
    final bought = await _flow(book).buy();
    await _resolveAccess();
    // Buying is nearly always followed by wanting to read it — carry
    // straight on into the download instead of making the user tap "Oku".
    if (bought && mounted) {
      await _flow(book).read(offerPurchasedExport: true);
    }
  }

  void _cancelDownload() {
    final book = _book;
    if (book != null) BookDownloadService.instance.cancel(book.id);
  }

  // Only the "mark as finished" direction syncs — un-marking has no
  // well-defined progress to report back (the user's real reading
  // position isn't tracked here), so that half just stays a local toggle.
  void _toggleFinished() {
    _setState(() => _isFinished = !_isFinished);
    context.showAppSnackBar(_isFinished
        ? BookDetailStrings.finishedAdded
        : BookDetailStrings.finishedRemoved);
    if (_isFinished) {
      BookApiService.updateProgress(widget.bookId, progress: 100)
          .then((_) => FinishedBooksSyncService.instance.notifyChanged())
          .catchError((_) {});
    }
  }

  // Optimistic: the local toggle is the UI's source of truth, the like/unlike
  // call is a best-effort sync — this is a real `LibraryBook.id`, unlike the
  // mock catalogue's ids, so (unlike BookDetailScreen) this one actually
  // persists. See BookApiService's doc comment.
  void _toggleFavorite() {
    _setState(() => _isFavorite = !_isFavorite);
    context.showAppSnackBar(_isFavorite
        ? BookDetailStrings.favoriteAdded
        : BookDetailStrings.favoriteRemoved);
    final bookId = widget.bookId.toString();
    final future = _isFavorite
        ? BookApiService.likeBook(bookId)
        : BookApiService.unlikeBook(bookId);
    // Only notifies once the like/unlike has actually landed server-side —
    // firing it immediately (before this even started) let LibraryScreen's
    // favorites tab re-fetch `wants_to=true` before the DELETE had taken
    // effect, so it came back still containing the book that was just
    // unliked and then never refreshed again. Silent on failure: nothing
    // changed server-side, so there's nothing for the list to pick up.
    future
        .then((_) => FavoritesSyncService.instance.notifyChanged())
        .catchError((_) {});
  }

  Future<void> _onShare(BookDetail book) async {
    final text = BookDetailStrings.shareText(
      book.name,
      book.authorNames,
      genres: book.genres.map((g) => g.name).toList(),
      pages: book.pageCount,
      synopsis: book.description,
    );
    final image = book.image;
    if (image != null && image.isNotEmpty) {
      // Reuses NetworkCoverImage's cache — the cover shown on this very
      // page is very likely cached on disk already, so this is usually
      // instant rather than a fresh download.
      try {
        final file = await DefaultCacheManager()
            .getSingleFile(ApiConfig.resolveImageUrl(image));
        await Share.shareXFiles([XFile(file.path)], text: text);
        return;
      } catch (_) {
        // Falls through to text-only share below.
      }
    }
    await Share.share(text);
  }

  void _openAuthor(LibraryBookAuthor author) {
    context.push(CatalogAuthorDetailScreen(authorId: author.id));
  }

  void _openGenre(BookDetailGenre genre) {
    context.push(
        CatalogGenreBooksScreen(genreId: genre.id, genreName: genre.name));
  }

  Future<void> _removeFromPurchased(BookDetail book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          BookDetailStrings.removeFromPurchased,
          style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800),
        ),
        content: Text(
          BookDetailStrings.removePurchasedConfirm(book.name),
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BookDetailStrings.cancel,
                style: TextStyle(color: AppColors.grey2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(BookDetailStrings.remove,
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _setState(() => _removingFromPurchased = true);
    try {
      await BookApiService.removeBoughtBook(book.id);
      if (!mounted) return;
      context
          .showAppSnackBar(BookDetailStrings.removedFromPurchased(book.name));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(() => _removingFromPurchased = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }
}
