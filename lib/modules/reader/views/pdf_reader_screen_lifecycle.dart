part of 'pdf_reader_screen.dart';

/// Screen open/close plumbing: restoring saved settings and page on open,
/// the app-lifecycle-driven streak ping, and switching to the reflowed text
/// reader when the reader picks that option from the settings sheet.
/// Slider position a text PDF opens at when nothing has been saved — see
/// [_PdfReaderScreenState._marginCrop]. Two thirds of the way up
/// [PdfMarginCropBox.maxFraction], so roughly 8% comes off each side: enough
/// to close a typical book's gutter without reaching the text block.
const double _defaultMarginCrop = 0.65;

extension _PdfReaderScreenLifecycle on _PdfReaderScreenState {
  void _handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _streakPing.flushResidual();
      case AppLifecycleState.resumed:
        _streakPing.start();
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _restoreState() async {
    await BookmarksStore.instance.load();
    final prefs = await SharedPreferences.getInstance();
    _initialPage = prefs.getInt('book_${_bookId}_pdf_page') ?? 0;
    _currentPage = _initialPage;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _eyeCare = prefs.getDouble('reader_eye_care') ?? 0.0;
    // New three-way mode; fall back to the old dark-gutter bool for anyone
    // upgrading (their dark gutter maps to night, otherwise light). With
    // neither ever saved (first PDF ever opened, or a fresh install), default
    // to night rather than the app theme — night is the app-wide reading
    // default regardless of the shell's own light/dark setting.
    final savedMode = prefs.getInt('reader_pdf_color_mode');
    final legacyDarkGutter = prefs.getBool('reader_pdf_dark_gutter');
    if (savedMode != null) {
      _colorMode = PdfColorMode
          .values[savedMode.clamp(0, PdfColorMode.values.length - 1)];
    } else if (legacyDarkGutter != null) {
      _colorMode = legacyDarkGutter ? PdfColorMode.night : PdfColorMode.light;
    } else {
      _colorMode = PdfColorMode.night;
    }
    // Continuous scroll is the default — see [PdfViewMode]. Paged (sideways,
    // one page per swipe) is opt-in for anyone who prefers reading it like a
    // normal book.
    //
    // The mode preference is app-wide, which is right for text PDFs but wrong
    // for an image book: a reader who once chose paged for a novel would then
    // have every manga open with its tall pages squeezed whole onto the screen
    // — the exact unreadable sliver [PdfViewMode.scroll] exists to avoid. So an
    // image book ignores the app-wide preference and opens in scroll unless a
    // choice was made *for this book*, which [_setViewMode] records separately.
    final bookMode = prefs.getInt('book_${_bookId}_pdf_view_mode');
    final defaultMode = widget.imageOnly
        ? PdfViewMode.scroll.index
        : (prefs.getInt('reader_pdf_view_mode') ?? PdfViewMode.scroll.index);
    _viewMode = PdfViewMode.values[
        (bookMode ?? defaultMode).clamp(0, PdfViewMode.values.length - 1)];
    // Fit-width is the default, matching the default scroll mode — see
    // [_setViewMode] for why the two travel together. Whole-page is what paged
    // mode needs (there's no way to scroll to the rest of a page fit-width
    // left below the fold), so it only kicks in once the user picks paged.
    final bookFitWidth = prefs.getBool('book_${_bookId}_pdf_fit_width');
    final defaultFitWidth = widget.imageOnly
        ? true
        : (prefs.getBool('reader_pdf_fit_width') ??
            (_viewMode == PdfViewMode.scroll));
    _fitPolicy =
        (bookFitWidth ?? defaultFitWidth) ? PdfFitMode.width : PdfFitMode.page;
    // Margin trimming, per book first (margins are a property of the book,
    // not of the reader — a novel set with generous gutters needs more of it
    // than a densely typeset one) and falling back to the app-wide choice.
    //
    // An image book opens with none: a scan or a manga page is printed to the
    // edge, so there is no blank margin to reclaim and cropping would take
    // the artwork instead. Everything else opens with a modest default trim
    // rather than at zero — a text PDF essentially always carries a print
    // margin, and leaving it there is the empty strip down each side this
    // setting exists to close.
    _marginCrop = prefs.getDouble('book_${_bookId}_pdf_margin_crop') ??
        prefs.getDouble('reader_pdf_margin_crop') ??
        (widget.imageOnly ? 0.0 : _defaultMarginCrop);
    _brightnessController.apply(_brightness);
    if (mounted) _setState(() {});
  }

  /// Records the preference and hands straight back to [PdfOpeningScreen],
  /// which owns the conversion.
  ///
  /// It deliberately does *not* convert here and push the text reader
  /// itself: the conversion drives PDFium over the whole document, and
  /// starting that while this screen's own [PdfViewer] still holds the same
  /// file open put two readers on one document. Replacing this route first
  /// means the viewer is torn down before any of that begins.
  Future<void> _switchToTextView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferFixedPrefKey(_bookId), false);
    await _saveProgress();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PdfOpeningScreen(
          filePath: widget.filePath,
          title: widget.title,
          bookId: _bookId,
          realBookId: widget.realBookId,
        ),
      ),
    );
  }
}
