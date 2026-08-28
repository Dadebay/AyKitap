part of 'reader_provider.dart';

/// Foldable/wide-window support for the EPUB reader: switches epub.js's own
/// two-column layout on when the window is expanded (a tablet, a desktop) or
/// a foldable is open in book posture, off otherwise. PDF and CBZ don't get
/// this — only the EPUB reader owns an [epubController] to drive.
///
/// Both [EpubController.setSpread] and [EpubController.updateTheme] (used
/// here for the gutter) are runtime calls into the *existing* WebView/
/// rendition, the same way [ReaderProviderAppearance.setTheme] already
/// changes the reader's colours mid-session — neither ever rebuilds
/// [EpubViewer] or recreates the WebView, so a fold opening or closing never
/// resets the current CFI, highlights or bookmarks the way tearing down and
/// re-mounting the viewer would.
extension ReaderProviderLayout on ReaderProvider {
  bool get isSpreadActive => _spreadActive;

  /// Visible gap between the two pages of a spread, in CSS px. Matches a real
  /// foldable's hinge width when one is reported, so the gutter lands over
  /// the crease rather than being an arbitrary decoration — clamped to a
  /// sane range since a hinge can be reported very narrow (a flexible fold
  /// with no physical gap) or, in principle, implausibly wide. Falls back to
  /// a fixed default on a wide window with no real hinge (a tablet, a
  /// desktop) — just enough to read as "two pages" rather than one column
  /// with a stray line down the middle.
  double get _spreadGutter {
    final hinge = _verticalHinge;
    if (hinge == null) return 28.0;
    return hinge.width.clamp(28.0, 96.0);
  }

  /// Called from [ReaderScreen]'s `didChangeDependencies` every time
  /// [MediaQuery] changes size or display features — window resize, device
  /// rotation, a fold opening or closing.
  void updateWindowSizeClass(WindowSizeClass windowSizeClass) {
    if (windowSizeClass.width == _windowWidth &&
        windowSizeClass.verticalHinge == _verticalHinge) {
      return;
    }
    _windowWidth = windowSizeClass.width;
    _verticalHinge = windowSizeClass.verticalHinge;
    _recomputeSpread();
  }

  /// Recomputes [_spreadActive] for whatever window/hinge/page-transition
  /// state is currently stored, and — once a rendition actually exists to
  /// receive it — pushes the result in. Called from here, from
  /// [ReaderProviderAppearance.setPageTransition] (Scroll opts out of spread
  /// regardless of window shape, so switching into or out of it can flip
  /// spread even though the window itself hasn't changed), and from
  /// [ReaderProviderCallbacks.onEpubLoaded].
  ///
  /// That last call site is what makes the [EpubController.isBookLoaded]
  /// guard below correct rather than just defensive: this screen's very
  /// first [updateWindowSizeClass] call lands during
  /// `didChangeDependencies`, well before the WebView has even mounted, and
  /// every [EpubController] command throws if called before the rendition
  /// exists ("Epub viewer is not loaded"). [_spreadActive] itself is still
  /// computed and stored on that early call — it's what
  /// `reader_view_epub_viewer.dart` reads for the *initial*
  /// `EpubDisplaySettings`, so the book opens in the right layout from its
  /// first frame — but the live push waits for `onEpubLoaded` to do it,
  /// exactly like the font size/line spacing/theme re-applies already there.
  void _recomputeSpread() {
    // Either signal alone is enough: a wide desktop/tablet window has no
    // hinge at all, and a folded phone in book posture can still measure
    // "compact" by raw per-pane width.
    final wantsSpread =
        _windowWidth == WindowWidthClass.expanded || _verticalHinge != null;
    _spreadActive =
        wantsSpread && _pageTransition != ReaderPageTransition.scroll;
    if (!epubController.isBookLoaded) return;
    epubController.setSpread(
        spread: _spreadActive ? EpubSpread.always : EpubSpread.none);
    epubController.updateTheme(theme: _buildEpubTheme());
  }
}
