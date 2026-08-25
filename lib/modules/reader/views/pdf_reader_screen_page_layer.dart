part of 'pdf_reader_screen.dart';

/// The page itself: [PdfViewer.file], its colour washes (night-mode invert,
/// sepia, eye-care) and the loading/error overlays that sit above it while
/// there's no page to show yet. Split out from the rest of the widget tree
/// (chrome — top/bottom bar, focus indicator) in pdf_reader_screen_body.dart
/// since this is the part of the Stack whose children actually depend on
/// [_error]/[_isLoading].
extension _PdfReaderScreenPageLayer on _PdfReaderScreenState {
  Widget _buildPageLayer(Color bg, bool isDarkSurface, bool nightMode) {
    return Stack(
      children: [
        if (_error == null)
          Positioned.fill(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              child: PdfNightModeFilter(
                // Inverts the rendered page to light-on-dark — the "göz
                // goraýyş" dark reading the user asked for. Ideal for text
                // PDFs (black-on-white becomes white-on-black) and poor for
                // scanned/manga pages (they become photo negatives), which
                // is why it's an opt-in mode rather than the default. Done
                // as a Flutter layer, so unlike PDFium's Android-only night
                // mode it now works identically on iOS.
                enabled: nightMode,
                // Trims the page's own blank print margins so the text block
                // reaches both screen edges instead of sitting between two
                // empty strips. See [PdfMarginCropBox] for why this is done
                // by sizing the viewport rather than by asking for more zoom.
                child: PdfMarginCropBox(
                  fraction: _marginCropFraction,
                  child: PdfViewer.file(
                    widget.filePath,
                    controller: _controller,
                    // The layout and the initial zoom are read when the viewer
                    // lays out, so changing either has to rebuild it — that's
                    // what varying the key does. `initialPageNumber` carries
                    // our place across that rebuild and across reopening the
                    // book. (Sepia and night aren't in the key: both are
                    // Flutter overlays, not render changes, so switching to or
                    // from them mustn't reload the file.)
                    key: ValueKey(
                        'pdf_${_fitPolicy.name}_${_viewMode.name}_$_initialPage'),
                    initialPageNumber: _initialPage + 1,
                    params: PdfViewerParams(
                      backgroundColor: bg,
                      // A long scanned book (a few hundred image-heavy pages,
                      // common for a CamScanner/phone-photo PDF) can push the
                      // default 100MB rendered-page cache and the default
                      // one-viewport-ahead/behind cache extent past what a
                      // budget Android phone's PDFium has room for, which
                      // surfaces as the whole app getting killed rather than
                      // a catchable Dart error — pdfium's crash isn't
                      // something a try/catch here can stop. Trading some
                      // scroll-ahead smoothness for a smaller memory
                      // footprint is worth it: a slightly-more-often
                      // re-rendered page beats the reader force-closing.
                      maxImageBytesCachedOnMemory: 40 * 1024 * 1024,
                      horizontalCacheExtent: 0.5,
                      verticalCacheExtent: 0.5,
                      // Paged mode lays pages left-to-right, one per sideways
                      // swipe, like a real page turn; scroll mode stacks them
                      // top-to-bottom with no gap so a tall webtoon page runs
                      // straight into the next. See [_layoutPages].
                      layoutPages: _layoutPages,
                      // Paged mode moves one page at a time along its own
                      // axis; locking the pan to that axis is what keeps a
                      // sideways swipe from drifting the page diagonally.
                      panAxis: _viewMode == PdfViewMode.paged
                          ? PanAxis.horizontal
                          : PanAxis.free,
                      // pdfrx's naming is the opposite of what it sounds like
                      // here: `alternativeFitZoom` fits *one page* (both axes)
                      // into the viewport — that's [PdfFitMode.page], "the
                      // whole page has to be on screen". `coverZoom` scales to
                      // the *document*'s full laid-out bounding box (all pages
                      // — see [_layoutPages]'s `documentSize`); for scroll
                      // mode's tall single-column strip that bounding box is
                      // far taller than it is wide, so covering it collapses
                      // to fitting the width — that's [PdfFitMode.width]. A
                      // prior migration from flutter_pdfview matched these to
                      // the wrong [PdfFitMode], which showed every PDF letter-
                      // boxed (whole page, margins left/right) regardless of
                      // which fit the reader had picked.
                      sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
                        // Continuous scroll has no "whole page visible, no
                        // scrolling" state the way paged mode does — a page
                        // there is always followed by more page below, so
                        // "fit page" would only mean shrinking it to letterbox
                        // inside the viewport (visible margins left/right,
                        // exactly the "stuck in the middle" look this is meant
                        // to avoid). So scroll mode always covers to the full
                        // width regardless of [_fitPolicy]; only paged mode
                        // still honors the whole-page choice.
                        // Asking for more than `coverZoom` here does nothing:
                        // pdfrx jumps to the initial page right after this and
                        // recomputes the zoom as
                        // `viewportWidth / (pageWidth + 2 * params.margin)`,
                        // capped at whatever was set here — so the page is
                        // always fit to its *full* width and can never be
                        // pushed past the edges from this callback. Closing
                        // the page's blank print margins is [PdfMarginCropBox]'s
                        // job instead; this callback only picks *which* fit.
                        calculateInitialZoom: (document, controller,
                                alternativeFitZoom, coverZoom) =>
                            (_fitPolicy == PdfFitMode.width ||
                                    _viewMode == PdfViewMode.scroll)
                                ? coverZoom
                                : alternativeFitZoom,
                      ),
                      onViewerReady: (document, controller) => _setState(() {
                        _totalPages = document.pages.length;
                        _isLoading = false;
                      }),
                      onPageChanged: _onPageChanged,
                      // The raw exception is developer noise, not something a
                      // reader should have to parse — log it and show a
                      // plain-language message instead. Returning an empty box
                      // lets this screen's own error state own the display.
                      errorBannerBuilder:
                          (context, error, stackTrace, documentRef) {
                        log('❌ PDF open error: $error');
                        // The builder runs during layout, so the state change
                        // has to wait for the frame to finish.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || _error != null) return;
                          _setState(() {
                            _error = ReaderPdfStrings.pdfOpenError;
                            _isLoading = false;
                          });
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Sepia eye-care wash ────────────────────────────────────────
        // A translucent warm tint laid over the whole page. Unlike night
        // mode this needs no native support — it's an ordinary Flutter layer
        // painted on top of the platform view, so it warms the page the same
        // way on Android and iOS. IgnorePointer keeps swipes/taps flowing
        // through to the PDF underneath.
        if (_colorMode == PdfColorMode.sepia && _error == null)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Color(0x24C8862A)),
            ),
          ),

        // ── Eye-care (blue-light) wash ─────────────────────────────────
        // A warm amber layer over the page, independent of the colour mode
        // so it stacks on top of light / sepia / night alike. Shared with
        // the EPUB reader via the same pref (see _eyeCare).
        if (readerEyeCareColor(_eyeCare, isDarkPage: isDarkSurface) != null &&
            _error == null)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                  color:
                      readerEyeCareColor(_eyeCare, isDarkPage: isDarkSurface)!),
            ),
          ),

        // Same opening animation the EPUB reader uses, so a book looks like
        // it's opening rather than the app looking like it's stalled.
        if (_isLoading)
          ReaderLoadingOverlay(
              backgroundColor: bg,
              isDarkSurface: isDarkSurface,
              message: ReaderStrings.bookOpening),

        if (_error != null)
          ReaderErrorOverlay(
              backgroundColor: bg,
              isDarkSurface: isDarkSurface,
              message: ReaderPdfStrings.pdfOpenError),
      ],
    );
  }
}
