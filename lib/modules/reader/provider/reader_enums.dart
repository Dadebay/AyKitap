import 'package:sakura_epub/sakura_epub.dart';

enum ReaderThemeMode { white, sepia, dark, black }

/// TZ §12.4 — the reader body fonts offered in the settings sheet. Each maps to
/// a bundled font file that's injected into the epub WebView (see
/// `ReaderProvider._applyReaderFont`) and a matching Flutter family for the
/// sheet's preview.
enum ReaderFontFamily { sanFrancisco, arial, notoSerif, openSans }

/// TZ §12.2 — the six page-change styles shown in the reference panel.
/// epub.js has no transition API, so each style's tween is a visual layer
/// applied in epubView.js's `_transitionSpec`; all six run on [EpubFlow.paginated].
/// Most are horizontal turns on a horizontal swipe; [scroll] (Prokrutka) is the
/// odd one — a vertical bottom-to-top slide driven by a *vertical* swipe, the
/// closest a paginated turn gets to the feel of scrolling to the next page.
enum ReaderPageTransition { slide, curl, overlay, scroll, shift, none }
