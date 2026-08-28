part of 'reader_provider.dart';

/// Builds the [EpubTheme] pushed into the WebView rendition: the reader body
/// font (injected as a base64 `@font-face`, since the WebView can't reach
/// Flutter's registered families) and the novel/manga CSS rule set.
extension ReaderProviderThemeCss on ReaderProvider {
  EpubTheme get currentEpubTheme => _buildEpubTheme();

  // ── Reader body font (TZ §12.4) ───────────────────────────────────────────
  // The epub renders in a WebView, so the chosen font can't come from Flutter's
  // registered families — it's read from assets, base64-encoded and injected as
  // an @font-face. The css/asset names line up so the injected face and the
  // theme's `font-family` rule refer to the same family.

  Future<void> _applyReaderFont() async {
    final family = _fontFamily;
    final asset = _fontAsset(family);
    try {
      final data = await rootBundle.load(asset);
      final b64 = base64Encode(data.buffer.asUint8List());
      epubController.setFontFamily(
        fontFamily: _fontCssName(family),
        fontBase64: b64,
        fontMimeType:
            asset.endsWith('.otf') ? 'font/opentype' : 'font/truetype',
      );
    } catch (e) {
      log('❌ Font apply error: $e');
    }
  }

  EpubTheme _buildEpubTheme() {
    final fontName = _fontCssName(_fontFamily);
    final css = _readerCss(fontName);
    return switch (_themeMode) {
      ReaderThemeMode.white => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
          foregroundColor: const Color(0xFF000000),
          customCss: css,
        ),
      ReaderThemeMode.sepia => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFFf5ebda)),
          foregroundColor: const Color(0xFF3E3329),
          customCss: css,
        ),
      ReaderThemeMode.dark => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
          foregroundColor: const Color(0xFFFFFFFF),
          customCss: css,
        ),
      ReaderThemeMode.black => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFF000000)),
          foregroundColor: const Color(0xFFABAAB2),
          customCss: css,
        ),
    };
  }

  /// TZ §12.2 — whether the reader is in manga/webtoon layout.
  ///
  /// Always false now: every mode is paginated, and scroll/Prokrutka became a
  /// vertical *paginated* page-turn (a bottom-to-top slide on a vertical swipe)
  /// rather than epub.js's continuous scrolled flow, so no mode selects the
  /// manga image layout any more. Kept as a named getter — rather than inlining
  /// `false` — so the novel/manga split in [_readerCss] stays readable and a
  /// future continuous-scroll mode has one obvious place to switch back on.
  bool get _isMangaLayout => false;

  /// sakura_epub's `customCss` is a map of **CSS selector → { property: value }**
  /// (its `updateTheme` merges each selector's object into the epub.js theme
  /// rules). The old flat `{ 'font-family': … }` shape was silently ignored
  /// because those keys were treated as selectors with string values.
  ///
  /// Two layouts — novel and manga — picked by [_isMangaLayout]. Because the
  /// layout is derived from the page-transition mode, [setPageTransition] has
  /// to re-push the theme.
  ///
  /// Both layouts deliberately set the *same* properties on the *same*
  /// selectors and differ only in the values. epub.js reuses one `<style>` per
  /// theme and appends to it — Contents.addStylesheetRules calls insertRule at
  /// the end of the sheet and never clears it — so a property the new layout
  /// simply omits keeps the old layout's value instead of being reset. Every
  /// difference below therefore has to be spelled out on both sides.
  Map<String, dynamic> _readerCss(String fontName) {
    final manga = _isMangaLayout;
    return {
      // No padding here: epub.js writes `padding: 20px` directly onto the
      // book's <body> as an inline style when it paginates, and these rules
      // reach the page as a stylesheet, which an inline style outranks — so any
      // padding set here is silently ignored. The page's breathing room comes
      // from insetting the WebView itself (see ReaderScreen._viewerInset).
      'body': {
        'font-family': fontName,
        'line-height': '$_lineSpacing',
        // epub.js sets its own column-gap inline on this same body element
        // whenever spread is active (Contents.columns) — like the padding
        // this class's own doc comment describes, an inline style outranks
        // a plain stylesheet rule, so this needs `!important` to actually
        // win and widen the gutter to the real hinge's width. Omitted while
        // spread is off: with a single column the property has nothing to
        // gap, and epub.js never clears old theme rules (see this class's
        // doc comment), so there's no stale value to worry about once
        // spread turns back on — [ReaderProviderLayout.updateWindowSizeClass]
        // always re-pushes the theme in the same call that flips spread.
        if (_spreadActive) 'column-gap': '${_spreadGutter}px !important',
      },
      // Manga: fill the column at the panel's own aspect ratio. The height cap
      // is what letterboxes a tall page and opens a band of background under
      // it, which is exactly what breaks the single-strip illusion — hence
      // `none`. A novel keeps the cap so an illustration can't outgrow a page.
      'img': {
        'max-width': '100%',
        'max-height': manga ? 'none' : '96vh',
        'width': manga ? '100%' : 'auto',
        'height': 'auto',
        'display': 'block',
        'margin-left': manga ? '0' : 'auto',
        'margin-right': manga ? '0' : 'auto',
        // Irrelevant once the box matches the intrinsic ratio; set only so the
        // novel layout's `contain` cannot linger in the sheet.
        'object-fit': manga ? 'fill' : 'contain',
      },
      'svg': {
        'max-width': '100%',
        'max-height': manga ? 'none' : '96vh',
        'width': manga ? '100%' : 'auto',
        'display': 'block',
        'margin-left': manga ? '0' : 'auto',
        'margin-right': manga ? '0' : 'auto',
      },
      // Cover pages: a body whose *only* content is one picture — either a
      // bare <img>/<svg> or one wrapped in a single <div> (Calibre emits
      // <body><div><svg><image/></svg></div>). The :only-child chain keeps
      // this from ever matching a text page that happens to contain an
      // illustration. Centring is done with flex rather than by forcing a
      // height, because these covers carry preserveAspectRatio="none" and
      // would stretch if the box's aspect ratio were changed.
      //
      // Neutralised rather than dropped in manga layout: pinning every
      // full-page panel to 100vh would letterbox the whole strip.
      'body:has(> img:only-child), body:has(> svg:only-child), body:has(> div:only-child > img:only-child), body:has(> div:only-child > svg:only-child)':
          {
        'display': manga ? 'block' : 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        'height': manga ? 'auto' : '100vh',
        'margin': '0',
        'padding': '0',
      },
      // Calibre wraps each panel in its own <p>/<div>, and those wrappers'
      // margins are what show up as seams between panels. Manga-only, and
      // unlike the rules above it has no reset value — a book's own paragraph
      // margins are unknowable, so there is nothing to restore them to. Left
      // out entirely for novels; switching back re-renders the views, which
      // rebuilds the stylesheet from scratch. The :only-child chain keeps this
      // off ordinary text paragraphs.
      if (manga)
        'p:has(> img:only-child), div:has(> img:only-child), p:has(> svg:only-child), div:has(> svg:only-child)':
            {
          'margin': '0',
          'padding': '0',
        },
    };
  }

  static String _fontCssName(ReaderFontFamily f) => switch (f) {
        ReaderFontFamily.sanFrancisco => 'SanFrancisco',
        ReaderFontFamily.arial => 'Arial',
        ReaderFontFamily.notoSerif => 'NotoSerif',
        ReaderFontFamily.openSans => 'OpenSans',
      };

  static String _fontAsset(ReaderFontFamily f) => switch (f) {
        ReaderFontFamily.sanFrancisco => 'assets/fonts/SF-Pro-Text-Regular.otf',
        ReaderFontFamily.arial => 'assets/fonts/Arial-Regular.ttf',
        ReaderFontFamily.notoSerif => 'assets/fonts/NotoSerif-Regular.ttf',
        ReaderFontFamily.openSans => 'assets/fonts/OpenSans-Regular.ttf',
      };
}
