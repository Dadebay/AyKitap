part of 'pdf_reader_screen.dart';

/// The page itself: [PdfViewer.file], its colour washes (night-mode invert,
/// sepia, eye-care) and the loading/error overlays that sit above it while
/// there's no page to show yet. Split out from the rest of the widget tree
/// (chrome — top/bottom bar, focus indicator) in pdf_reader_screen_body.dart
/// since this is the part of the Stack whose children actually depend on
/// [_error]/[_isLoading].
/// Mirrors pdfrx's own default page shadow. Restated rather than left to the
/// package default because night mode has to be able to turn it off (see
/// where it's used), which means naming it here anyway — and this way the
/// reader's look stays put if that default ever changes upstream.
const _pageDropShadow = BoxShadow(
  color: Colors.black54,
  blurRadius: 4,
  spreadRadius: 2,
  offset: Offset(2, 2),
);

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
                      // The gutter behind the pages — and it is painted
                      // *inside* the night filter above, so it has to be
                      // given the colour that survives inversion rather than
                      // the one it should end up being.
                      //
                      // Night mode aims at pure black rather than [bg]'s
                      // near-black: the page itself inverts from white paper
                      // to #000, so anything else here leaves the page
                      // floating as a slightly different shade on its own
                      // background. The chrome around the viewer keeps [bg]
                      // (it sits outside the filter) — only what butts up
                      // against the page has to match it.
                      backgroundColor: nightMode
                          ? PdfNightModeFilter.preInverted(Colors.black)
                          : bg,
                      // The shadow is there to lift a white page off a light
                      // gutter. Night mode has neither — page and gutter are
                      // both #000 — so it has nothing left to separate, and
                      // the filter renders `Colors.black54` as a *white* glow
                      // around every page, which is exactly what it looked
                      // like.
                      pageDropShadow: nightMode ? null : _pageDropShadow,
                      // Continuous pages are full-bleed. pdfrx's default
                      // eight-pixel page margin otherwise survives even with
                      // a zero-gap custom layout and leaves a thin gutter on
                      // both sides. Paged mode keeps the normal separation.
                      margin: _viewMode == PdfViewMode.scroll ? 0.0 : 8.0,
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
                      // into the viewport, while `coverZoom` scales to the
                      // *document*'s full laid-out bounding box (all pages —
                      // see [_layoutPages]'s `documentSize`). Which of the two
                      // is right depends on the shape that box takes in each
                      // mode, not on [_fitPolicy] — see [pdfInitialZoom].
                      sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
                        calculateInitialZoom: (document, controller,
                                alternativeFitZoom, coverZoom) =>
                            pdfInitialZoom(
                          viewMode: _viewMode,
                          fitPageZoom: alternativeFitZoom,
                          coverZoom: coverZoom,
                        ),
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
