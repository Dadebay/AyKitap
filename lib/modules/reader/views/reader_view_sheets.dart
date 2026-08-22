part of 'reader_view.dart';

/// Bottom-sheet flows this screen opens: settings (incl. switching to the
/// original PDF), chapters, bookmarks and search — pure UI flow, kept
/// separate from the state changes they trigger (see reader_view_notes.dart
/// for the one exception, the selection toolbar's add/remove-note flow).
extension _ReaderViewSheets on _ReaderScreenState {
  void _showSettings(BuildContext context) async {
    final provider = context.read<ReaderProvider>();
    final switchToOriginalPdf = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: ReaderSettingsSheet(
            showOriginalPdfOption: widget.originalPdfPath != null),
      ),
    );
    final pdfPath = widget.originalPdfPath;
    if (switchToOriginalPdf != true || pdfPath == null || !context.mounted)
      return;
    await provider.saveAndClose();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferFixedPrefKey(widget.bookId), true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PdfReaderScreen(
          filePath: pdfPath,
          title: widget.bookTitle,
          bookId: widget.bookId,
          realBookId: widget.realBookId,
        ),
      ),
    );
  }

  void _showChapters(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: ChapterListSheet(
          bookTitle: widget.bookTitle,
          coverImage: widget.coverUrl,
          bookPages: widget.bookPages,
        ),
      ),
    );
  }

  void _showBookmarks(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const BookmarksSheet(),
      ),
    );
  }

  void _showSearch(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SearchSheet(provider: provider),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    context.showAppSnackBar(msg, isError: isError);
  }
}
