part of 'reader_provider.dart';

/// Reader appearance settings (TZ §12.2/§12.4): theme mode, font, size, line
/// spacing, screen brightness/eye-care, page transition and reading hand —
/// every setter here persists to `SharedPreferences` and pushes the change
/// into the live epub.js rendition via [ReaderProvider.epubController].
extension ReaderProviderAppearance on ReaderProvider {
  ReaderThemeMode get themeMode => _themeMode;
  ReaderFontFamily get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get lineSpacing => _lineSpacing;
  double get brightness => _brightness;
  double get eyeCare => _eyeCare;

  ReaderPageTransition get pageTransition => _pageTransition;
  bool get leftHandMode => _leftHandMode;

  Future<void> setTheme(ReaderThemeMode mode) async {
    _themeMode = mode;
    epubController.updateTheme(theme: _buildEpubTheme());
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_theme', mode.index);
  }

  Future<void> setFontSize(double size) async {
    _fontSize =
        size.clamp(ReaderProvider.minFontSize, ReaderProvider.maxFontSize);
    epubController.setFontSize(fontSize: _fontSize);
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', _fontSize);
  }

  Future<void> setFontFamily(ReaderFontFamily family) async {
    _fontFamily = family;
    await _applyReaderFont();
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_font', family.index);
  }

  Future<void> setLineSpacing(double spacing) async {
    _lineSpacing = spacing.clamp(1.0, 2.5);
    epubController.updateTheme(theme: _buildEpubTheme());
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_line_spacing', _lineSpacing);
  }

  Future<void> setBrightness(double value) async {
    _brightness = value.clamp(0.1, 1.0);
    _notify();
    await _applyReaderBrightness();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', _brightness);
  }

  Future<void> setEyeCare(double value) async {
    _eyeCare = value.clamp(0.0, 1.0);
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_eye_care', _eyeCare);
  }

  /// Drives the actual device screen brightness (TZ §12.4) via the shared
  /// [ReaderBrightnessController] — see its doc comment for why an explicit
  /// value is set even at 1.0. Control is only handed back on
  /// [_releaseBrightness], when the reader actually closes.
  Future<void> _applyReaderBrightness() =>
      _brightnessController.apply(_brightness);

  Future<void> _releaseBrightness() => _brightnessController.release();

  // ─────────────────────────────────────────────────────────────────────────
  // Page transition & reading direction (TZ §12.2)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setPageTransition(ReaderPageTransition transition) async {
    log('🔀 Page transition selected: ${transition.name}');
    _pageTransition = transition;
    // Every mode is paginated now (scroll/Prokrutka is a vertical *paginated*
    // turn, not epub.js's continuous scrolled flow) — so no `setFlow` here; the
    // book already loaded paginated and stays that way. The custom animation
    // layer in epubView.js plays the chosen tween on each turn; the theme is
    // re-pushed only because it's rebuilt from the mode we just changed.
    epubController.setPageTransition(mode: transition.name);
    // Scroll opts out of spread regardless of window shape — see
    // ReaderProviderLayout._recomputeSpread — so switching to or from it can
    // flip spread even though the window itself hasn't changed. Pushes its
    // own setSpread/updateTheme, so the plain updateTheme call this method
    // already made for the transition-mode CSS is folded into it instead.
    _recomputeSpread();
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_page_transition', transition.index);
  }

  Future<void> toggleLeftHand() async {
    _leftHandMode = !_leftHandMode;
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_left_hand', _leftHandMode);
  }
}
